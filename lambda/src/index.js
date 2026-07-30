const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  QueryCommand,
  ScanCommand,
  UpdateCommand,
  DeleteCommand,
} = require("@aws-sdk/lib-dynamodb");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const { randomUUID } = require("crypto");

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const s3 = new S3Client({});
const ses = new SESClient({});

const USERS_TABLE = process.env.USERS_TABLE;
const HEALTH_SNAPSHOTS_TABLE = process.env.HEALTH_SNAPSHOTS_TABLE;
const CHALLENGES_TABLE = process.env.CHALLENGES_TABLE;
const FRIENDSHIPS_TABLE = process.env.FRIENDSHIPS_TABLE;
const ACTIVITY_TABLE = process.env.ACTIVITY_TABLE;
const FEED_TABLE = process.env.FEED_TABLE;
const PROFILE_IMAGES_BUCKET = process.env.PROFILE_IMAGES_BUCKET;

// Public Challenges (Feature 1)
const PUBLIC_CHALLENGES = [
  { id: 'bronze-walker', title: 'Bronze Walker', metric: 'steps', target: 5000, tier: 'bronze', description: 'Average 5,000 steps per day for 7 days' },
  { id: 'silver-walker', title: 'Silver Walker', metric: 'steps', target: 10000, tier: 'silver', description: 'Average 10,000 steps per day for 7 days' },
  { id: 'gold-walker', title: 'Gold Walker', metric: 'steps', target: 15000, tier: 'gold', description: 'Average 15,000 steps per day for 7 days' },
  { id: 'bronze-hiker', title: 'Bronze Hiker', metric: 'distanceWalked', target: 3, tier: 'bronze', description: 'Average 3km walked per day for 7 days' },
  { id: 'silver-hiker', title: 'Silver Hiker', metric: 'distanceWalked', target: 5, tier: 'silver', description: 'Average 5km walked per day for 7 days' },
  { id: 'gold-hiker', title: 'Gold Hiker', metric: 'distanceWalked', target: 8, tier: 'gold', description: 'Average 8km walked per day for 7 days' },
  { id: 'bronze-sleeper', title: 'Bronze Sleeper', metric: 'totalSleep', target: 7, tier: 'bronze', description: 'Average 7 hours sleep per day for 7 days' },
  { id: 'silver-sleeper', title: 'Silver Sleeper', metric: 'totalSleep', target: 8, tier: 'silver', description: 'Average 8 hours sleep per day for 7 days' },
  { id: 'gold-sleeper', title: 'Gold Sleeper', metric: 'totalSleep', target: 9, tier: 'gold', description: 'Average 9 hours sleep per day for 7 days' },
  { id: 'bronze-runner', title: 'Bronze Runner', metric: 'distanceRan', target: 2, tier: 'bronze', description: 'Average 2km running per day for 7 days' },
  { id: 'silver-runner', title: 'Silver Runner', metric: 'distanceRan', target: 4, tier: 'silver', description: 'Average 4km running per day for 7 days' },
  { id: 'gold-runner', title: 'Gold Runner', metric: 'distanceRan', target: 6, tier: 'gold', description: 'Average 6km running per day for 7 days' },
  { id: 'bronze-sun', title: 'Bronze Sun Seeker', metric: 'timeInDaylight', target: 30, tier: 'bronze', description: 'Average 30 min in sun per day for 7 days' },
  { id: 'silver-sun', title: 'Silver Sun Seeker', metric: 'timeInDaylight', target: 60, tier: 'silver', description: 'Average 60 min in sun per day for 7 days' },
  { id: 'gold-sun', title: 'Gold Sun Seeker', metric: 'timeInDaylight', target: 120, tier: 'gold', description: 'Average 120 min in sun per day for 7 days' },
];

exports.handler = async (event) => {
  const { routeKey, body, requestContext, pathParameters, headers } = event;
  
  // Extract user ID from JWT token (Apple ID token or Cognito token)
  let userId = requestContext?.authorizer?.jwt?.claims?.sub;
  
  // If no Cognito authorizer, decode from Authorization header
  if (!userId && headers?.authorization) {
    const token = headers.authorization.replace("Bearer ", "");
    userId = decodeUserIdFromJWT(token);
  }

  try {
    switch (routeKey) {
      case "GET /health":
        return response(200, { status: "ok", service: "agon-api", timestamp: new Date().toISOString() });

      case "GET /users":
        return await getAllUsers();

      case "GET /profile":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getProfile(userId);

      case "PUT /profile":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await updateProfile(userId, JSON.parse(body));

      case "POST /health/sync":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await syncHealth(userId, JSON.parse(body));

      case "GET /health/history":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getHealthHistory(userId, event.queryStringParameters);

      case "GET /leaderboard/{challengeId}":
        if (!userId) return response(401, { error: "Unauthorized" });
        const challengeId = pathParameters?.challengeId;
        return await getLeaderboard(challengeId, userId);

      case "POST /challenges":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await createChallenge(userId, JSON.parse(body));

      case "GET /challenges":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await listChallenges(userId);

      case "POST /challenges/{challengeId}/join":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await joinChallenge(userId, pathParameters?.challengeId);

      case "GET /challenges/{challengeId}":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getChallengeDetails(userId, pathParameters?.challengeId);

      case "DELETE /challenges/{challengeId}":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await deleteChallenge(userId, pathParameters?.challengeId);

      case "POST /challenges/{challengeId}/leave":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await leaveChallenge(userId, pathParameters?.challengeId);

      // Users
      case "GET /users/{userId}":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getUserProfile(pathParameters?.userId, userId);

      // Friends
      case "POST /friends/request":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await sendFriendRequest(userId, JSON.parse(body));

      case "POST /profile/avatar":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await uploadAvatar(userId, body);

      case "PUT /profile/goals":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await saveGoals(userId, JSON.parse(body));

      case "GET /profile/goals":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getGoals(userId);

      case "GET /friends":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getFriends(userId);

      case "POST /friends/{friendId}/accept":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await acceptFriendRequest(userId, pathParameters?.friendId);

      case "POST /friends/{friendId}/reject":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await rejectFriendRequest(userId, pathParameters?.friendId);

      case "DELETE /friends/{friendId}":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await removeFriend(userId, pathParameters?.friendId);

      // Activity
      case "GET /activity":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getActivityFeed(userId);

      // Feedback
      case "POST /feedback":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await submitFeedback(userId, JSON.parse(body));

      // Public Challenges (Feature 1)
      case "GET /challenges/public":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getPublicChallenges(userId);

      case "POST /challenges/public/{challengeId}/join":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await joinPublicChallenge(userId, pathParameters?.challengeId);

      // Trophies (Feature 1)
      case "POST /trophies/check":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await checkTrophies(userId);

      case "GET /trophies/{userId}":
        return await getTrophies(pathParameters?.userId);

      // Feed (Feature 5)
      case "POST /feed":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await createFeedPost(userId, JSON.parse(body));

      case "GET /feed":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getFeed(userId);

      case "POST /feed/{postId}/like":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await likeFeedPost(userId, pathParameters?.postId);

      case "POST /feed/{postId}/comment":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await commentOnFeedPost(userId, pathParameters?.postId, JSON.parse(body));

      case "GET /feed/{postId}/comments":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getFeedPostComments(pathParameters?.postId);

      // Rivals (Feature 6)
      case "POST /rivals":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await addRival(userId, JSON.parse(body));

      case "GET /rivals":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await getRivals(userId);

      case "DELETE /rivals/{rivalId}":
        if (!userId) return response(401, { error: "Unauthorized" });
        return await removeRival(userId, pathParameters?.rivalId);

      default:
        return response(404, { error: "Route not found" });
    }
  } catch (error) {
    console.error("Error:", error);
    return response(500, { error: "Internal server error" });
  }
};

// Decode the 'sub' claim from a JWT without verification (for dev)
// In production, verify the token signature
function decodeUserIdFromJWT(token) {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const payload = JSON.parse(Buffer.from(parts[1], "base64url").toString());
    return payload.sub || null;
  } catch {
    return null;
  }
}

// MARK: - Profile

async function getAllUsers() {
  const result = await dynamo.send(
    new ScanCommand({
      TableName: USERS_TABLE,
      ProjectionExpression: "userId, displayName, email",
    })
  );

  return response(200, { users: result.Items || [] });
}

async function getProfile(userId) {
  const result = await dynamo.send(
    new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    })
  );

  if (!result.Item) {
    return response(404, { error: "Profile not found" });
  }

  return response(200, result.Item);
}

async function updateProfile(userId, data) {
  // Build update expression dynamically - only update fields that are provided
  const updates = [];
  const names = {};
  const values = {};

  if (data.email !== undefined) {
    updates.push("#email = :email");
    names["#email"] = "email";
    values[":email"] = data.email;
  }
  if (data.displayName !== undefined) {
    updates.push("#displayName = :displayName");
    names["#displayName"] = "displayName";
    values[":displayName"] = data.displayName;
  }
  if (data.provider !== undefined) {
    updates.push("#provider = :provider");
    names["#provider"] = "provider";
    values[":provider"] = data.provider;
  }
  if (data.avatarUrl !== undefined) {
    updates.push("#avatarUrl = :avatarUrl");
    names["#avatarUrl"] = "avatarUrl";
    values[":avatarUrl"] = data.avatarUrl;
  }
  if (data.bio !== undefined) {
    updates.push("#bio = :bio");
    names["#bio"] = "bio";
    values[":bio"] = data.bio;
  }
  if (data.coolFact !== undefined) {
    updates.push("#coolFact = :coolFact");
    names["#coolFact"] = "coolFact";
    values[":coolFact"] = data.coolFact;
  }
  if (data.description !== undefined) {
    updates.push("#description = :description");
    names["#description"] = "description";
    values[":description"] = data.description;
  }

  updates.push("#updatedAt = :updatedAt");
  names["#updatedAt"] = "updatedAt";
  values[":updatedAt"] = new Date().toISOString();

  // Set createdAt only if it doesn't exist
  updates.push("#createdAt = if_not_exists(#createdAt, :createdAt)");
  names["#createdAt"] = "createdAt";
  values[":createdAt"] = data.createdAt || new Date().toISOString();

  await dynamo.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: "SET " + updates.join(", "),
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
    })
  );

  // Return the full profile
  const result = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId } })
  );

  return response(200, result.Item);
}

// MARK: - Health Sync

async function syncHealth(userId, data) {
  // Support both single day {date, metrics} and multiple days {days: [{date, metrics}, ...]}
  const days = data.days
    ? data.days
    : [{ date: data.date, metrics: data.metrics }];

  const syncedAt = new Date().toISOString();
  const syncedDates = [];

  for (const day of days) {
    const date = day.date || new Date().toISOString().split("T")[0];

    const item = {
      userId,
      date,
      metrics: day.metrics || {},
      syncedAt,
    };

    await dynamo.send(
      new PutCommand({
        TableName: HEALTH_SNAPSHOTS_TABLE,
        Item: item,
      })
    );

    syncedDates.push(date);
  }

  return response(200, { message: "Health data synced", dates: syncedDates });
}

// MARK: - Leaderboard

async function getLeaderboard(challengeId, currentUserId) {
  const today = new Date().toISOString().split("T")[0];

  // Get all health snapshots for today (all users)
  // In production, this would filter by challenge participants
  const result = await dynamo.send(
    new ScanCommand({
      TableName: HEALTH_SNAPSHOTS_TABLE,
      FilterExpression: "#d = :today",
      ExpressionAttributeNames: { "#d": "date" },
      ExpressionAttributeValues: { ":today": today },
    })
  );

  const snapshots = result.Items || [];

  // Get user profiles for display names
  const userIds = [...new Set(snapshots.map((s) => s.userId))];
  const users = {};

  for (const uid of userIds) {
    const userResult = await dynamo.send(
      new GetCommand({
        TableName: USERS_TABLE,
        Key: { userId: uid },
      })
    );
    if (userResult.Item) {
      users[uid] = userResult.Item;
    }
  }

  // Calculate scores (total steps as default metric for now)
  const participants = snapshots
    .map((snapshot) => {
      const metrics = snapshot.metrics || {};
      const score = metrics.steps || 0;
      const user = users[snapshot.userId] || {};

      return {
        userId: snapshot.userId,
        displayName: user.displayName || "Unknown",
        score: Math.round(score),
        metrics: {
          steps: metrics.steps || 0,
          exerciseMinutes: metrics.exerciseMinutes || 0,
          distanceWalked: metrics.distanceWalked || 0,
        },
        isCurrentUser: snapshot.userId === currentUserId,
      };
    })
    .sort((a, b) => b.score - a.score)
    .map((p, index) => ({ ...p, rank: index + 1 }));

  return response(200, {
    challengeId,
    date: today,
    metric: "steps",
    participants,
    totalParticipants: participants.length,
  });
}

// MARK: - Health History

async function getHealthHistory(userId, queryParams) {
  const days = parseInt(queryParams?.days || "30");
  const today = new Date();
  const startDate = new Date(today.getTime() - days * 24 * 60 * 60 * 1000);

  const result = await dynamo.send(
    new QueryCommand({
      TableName: HEALTH_SNAPSHOTS_TABLE,
      KeyConditionExpression: "userId = :userId AND #d BETWEEN :start AND :end",
      ExpressionAttributeNames: { "#d": "date" },
      ExpressionAttributeValues: {
        ":userId": userId,
        ":start": startDate.toISOString().split("T")[0],
        ":end": today.toISOString().split("T")[0],
      },
      ScanIndexForward: true,
    })
  );

  return response(200, { snapshots: result.Items || [] });
}

// MARK: - Challenges

async function createChallenge(userId, data) {
  const { metric, duration, invitedUserIds } = data;

  if (!metric || !duration) {
    return response(400, { error: "metric and duration are required" });
  }

  const validMetrics = ["steps", "exerciseMinutes", "distanceWalked", "distanceRan", "totalSleep", "timeInDaylight"];
  if (!validMetrics.includes(metric)) {
    return response(400, { error: `metric must be one of: ${validMetrics.join(", ")}` });
  }

  const startDate = new Date().toISOString();

  // Parse duration string to days
  let durationDays;
  switch (duration) {
    case "1d": durationDays = 1; break;
    case "1w": durationDays = 7; break;
    case "1m": durationDays = 30; break;
    default: durationDays = 7;
  }

  const endDate = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString();

  const item = {
    challengeId: randomUUID(),
    creatorId: userId,
    metric,
    startDate,
    endDate,
    status: "active",
    participants: [userId, ...(invitedUserIds || [])],
    createdAt: new Date().toISOString(),
  };

  await dynamo.send(
    new PutCommand({
      TableName: CHALLENGES_TABLE,
      Item: item,
    })
  );

  return response(201, item);
}

async function listChallenges(userId) {
  // Get challenges created by the user
  const createdResult = await dynamo.send(
    new QueryCommand({
      TableName: CHALLENGES_TABLE,
      IndexName: "creatorId-index",
      KeyConditionExpression: "creatorId = :userId",
      ExpressionAttributeValues: { ":userId": userId },
    })
  );

  // Get all challenges where user is a participant (scan with filter)
  const participantResult = await dynamo.send(
    new ScanCommand({
      TableName: CHALLENGES_TABLE,
      FilterExpression: "contains(participants, :userId)",
      ExpressionAttributeValues: { ":userId": userId },
    })
  );

  // Merge and deduplicate
  const challengeMap = {};
  for (const item of [...(createdResult.Items || []), ...(participantResult.Items || [])]) {
    challengeMap[item.challengeId] = item;
  }

  // Mark completed challenges based on endDate
  const now = new Date().toISOString();
  const challenges = Object.values(challengeMap)
    .map((c) => {
      if (c.status === "active" && c.endDate && c.endDate < now) {
        return { ...c, status: "completed" };
      }
      return c;
    })
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  return response(200, { challenges });
}

async function joinChallenge(userId, challengeId) {
  if (!challengeId) {
    return response(400, { error: "challengeId is required" });
  }

  // Get the challenge
  const result = await dynamo.send(
    new GetCommand({
      TableName: CHALLENGES_TABLE,
      Key: { challengeId },
    })
  );

  if (!result.Item) {
    return response(404, { error: "Challenge not found" });
  }

  const challenge = result.Item;

  if (challenge.participants.includes(userId)) {
    return response(400, { error: "Already a participant" });
  }

  if (challenge.status !== "active") {
    return response(400, { error: "Challenge is not active" });
  }

  // Add user to participants
  await dynamo.send(
    new UpdateCommand({
      TableName: CHALLENGES_TABLE,
      Key: { challengeId },
      UpdateExpression: "SET participants = list_append(participants, :newUser)",
      ExpressionAttributeValues: {
        ":newUser": [userId],
      },
    })
  );

  return response(200, { message: "Joined challenge", challengeId });
}

async function getChallengeDetails(userId, challengeId) {
  if (!challengeId) {
    return response(400, { error: "challengeId is required" });
  }

  const result = await dynamo.send(
    new GetCommand({
      TableName: CHALLENGES_TABLE,
      Key: { challengeId },
    })
  );

  if (!result.Item) {
    return response(404, { error: "Challenge not found" });
  }

  const challenge = result.Item;
  const { metric, startDate, endDate, participants } = challenge;

  // Calculate scores for each participant
  const scores = [];
  for (const participantId of participants) {
    // Query health snapshots between startDate and endDate
    const snapshotResult = await dynamo.send(
      new QueryCommand({
        TableName: HEALTH_SNAPSHOTS_TABLE,
        KeyConditionExpression: "userId = :userId AND #d BETWEEN :start AND :end",
        ExpressionAttributeNames: { "#d": "date" },
        ExpressionAttributeValues: {
          ":userId": participantId,
          ":start": startDate.split("T")[0],
          ":end": endDate.split("T")[0],
        },
      })
    );

    const snapshots = snapshotResult.Items || [];
    const totalScore = snapshots.reduce((sum, snapshot) => {
      const metrics = snapshot.metrics || {};
      return sum + (metrics[metric] || 0);
    }, 0);

    // Get user display name
    const userResult = await dynamo.send(
      new GetCommand({
        TableName: USERS_TABLE,
        Key: { userId: participantId },
      })
    );
    const user = userResult.Item || {};

    scores.push({
      userId: participantId,
      displayName: user.displayName || "Unknown",
      avatarUrl: user.avatarUrl || null,
      score: Math.round(totalScore),
      isCurrentUser: participantId === userId,
    });
  }

  // Sort by score descending and assign ranks
  scores.sort((a, b) => b.score - a.score);
  scores.forEach((s, i) => (s.rank = i + 1));

  return response(200, {
    ...challenge,
    scores,
  });
}

async function deleteChallenge(userId, challengeId) {
  if (!challengeId) {
    return response(400, { error: "challengeId is required" });
  }

  const result = await dynamo.send(
    new GetCommand({
      TableName: CHALLENGES_TABLE,
      Key: { challengeId },
    })
  );

  if (!result.Item) {
    return response(404, { error: "Challenge not found" });
  }

  if (result.Item.creatorId !== userId) {
    return response(403, { error: "Only the challenge creator can delete this challenge" });
  }

  await dynamo.send(
    new DeleteCommand({
      TableName: CHALLENGES_TABLE,
      Key: { challengeId },
    })
  );

  return response(200, { message: "Challenge deleted", challengeId });
}

async function leaveChallenge(userId, challengeId) {
  if (!challengeId) {
    return response(400, { error: "challengeId is required" });
  }

  const result = await dynamo.send(
    new GetCommand({
      TableName: CHALLENGES_TABLE,
      Key: { challengeId },
    })
  );

  if (!result.Item) {
    return response(404, { error: "Challenge not found" });
  }

  const challenge = result.Item;

  if (!challenge.participants.includes(userId)) {
    return response(400, { error: "Not a participant in this challenge" });
  }

  const updatedParticipants = challenge.participants.filter((p) => p !== userId);

  // If no participants left, delete the challenge
  if (updatedParticipants.length === 0) {
    await dynamo.send(
      new DeleteCommand({
        TableName: CHALLENGES_TABLE,
        Key: { challengeId },
      })
    );
    return response(200, { message: "Left challenge. Challenge deleted (no participants remaining)", challengeId });
  }

  // Otherwise update participants list
  await dynamo.send(
    new UpdateCommand({
      TableName: CHALLENGES_TABLE,
      Key: { challengeId },
      UpdateExpression: "SET participants = :participants",
      ExpressionAttributeValues: {
        ":participants": updatedParticipants,
      },
    })
  );

  return response(200, { message: "Left challenge", challengeId });
}

// MARK: - User Profile by ID

async function getUserProfile(targetUserId, currentUserId) {
  if (!targetUserId) {
    return response(400, { error: "userId is required" });
  }

  // Get user profile
  const userResult = await dynamo.send(
    new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId: targetUserId },
    })
  );

  if (!userResult.Item) {
    return response(404, { error: "User not found" });
  }

  // Get recent health snapshots (last 7 days)
  const today = new Date();
  const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
  const startDate = sevenDaysAgo.toISOString().split("T")[0];
  const endDate = today.toISOString().split("T")[0];

  const snapshotsResult = await dynamo.send(
    new QueryCommand({
      TableName: HEALTH_SNAPSHOTS_TABLE,
      KeyConditionExpression: "userId = :userId AND #d BETWEEN :start AND :end",
      ExpressionAttributeNames: { "#d": "date" },
      ExpressionAttributeValues: {
        ":userId": targetUserId,
        ":start": startDate,
        ":end": endDate,
      },
    })
  );

  // Get current user's snapshots for comparison
  let yourSnapshots = [];
  if (currentUserId && currentUserId !== targetUserId) {
    const yourResult = await dynamo.send(
      new QueryCommand({
        TableName: HEALTH_SNAPSHOTS_TABLE,
        KeyConditionExpression: "userId = :userId AND #d BETWEEN :start AND :end",
        ExpressionAttributeNames: { "#d": "date" },
        ExpressionAttributeValues: {
          ":userId": currentUserId,
          ":start": startDate,
          ":end": endDate,
        },
      })
    );
    yourSnapshots = yourResult.Items || [];
  }

  // Get active challenges count
  const challengesResult = await dynamo.send(
    new ScanCommand({
      TableName: CHALLENGES_TABLE,
      FilterExpression: "contains(participants, :userId) AND #s = :active",
      ExpressionAttributeNames: { "#s": "status" },
      ExpressionAttributeValues: {
        ":userId": targetUserId,
        ":active": "active",
      },
    })
  );

  return response(200, {
    ...userResult.Item,
    recentSnapshots: snapshotsResult.Items || [],
    yourSnapshots,
    activeChallengesCount: (challengesResult.Items || []).length,
  });
}

// MARK: - Goals

async function saveGoals(userId, goals) {
  await dynamo.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: "SET goals = :goals, updatedAt = :now",
      ExpressionAttributeValues: {
        ":goals": goals,
        ":now": new Date().toISOString(),
      },
    })
  );

  return response(200, { message: "Goals saved", goals });
}

async function getGoals(userId) {
  const result = await dynamo.send(
    new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    })
  );

  return response(200, { goals: result.Item?.goals || {} });
}

// MARK: - Avatar Upload

async function uploadAvatar(userId, body) {
  const key = `avatars/${userId}.jpg`;

  // Generate presigned URL for direct upload from iOS
  const command = new PutObjectCommand({
    Bucket: PROFILE_IMAGES_BUCKET,
    Key: key,
    ContentType: "image/jpeg",
  });

  const presignedUrl = await getSignedUrl(s3, command, { expiresIn: 300 });
  const publicUrl = `https://${PROFILE_IMAGES_BUCKET}.s3.eu-west-2.amazonaws.com/${key}`;

  // Update user profile with avatar URL
  await dynamo.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: "SET avatarUrl = :url, updatedAt = :now",
      ExpressionAttributeValues: {
        ":url": publicUrl,
        ":now": new Date().toISOString(),
      },
    })
  );

  return response(200, { uploadUrl: presignedUrl, avatarUrl: publicUrl });
}

// MARK: - Friends

async function sendFriendRequest(userId, data) {
  const { friendId } = data;
  if (!friendId) return response(400, { error: "friendId is required" });
  if (friendId === userId) return response(400, { error: "Cannot friend yourself" });

  // Check if already friends or pending
  const existing = await dynamo.send(
    new GetCommand({ TableName: FRIENDSHIPS_TABLE, Key: { userId, friendId } })
  );
  if (existing.Item) {
    return response(400, { error: "Friend request already exists" });
  }

  // Create pending friendship (from sender's perspective)
  await dynamo.send(
    new PutCommand({
      TableName: FRIENDSHIPS_TABLE,
      Item: { userId, friendId, status: "pending_sent", createdAt: new Date().toISOString() },
    })
  );

  // Create pending friendship (from receiver's perspective)
  await dynamo.send(
    new PutCommand({
      TableName: FRIENDSHIPS_TABLE,
      Item: { userId: friendId, friendId: userId, status: "pending_received", createdAt: new Date().toISOString() },
    })
  );

  // Add to activity feed
  await addActivity(friendId, "friend_request", `You have a new friend request`, userId);

  return response(200, { message: "Friend request sent" });
}

async function getFriends(userId) {
  const result = await dynamo.send(
    new QueryCommand({
      TableName: FRIENDSHIPS_TABLE,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: { ":uid": userId },
    })
  );

  const friendships = result.Items || [];

  // Get user profiles for each friend
  const enriched = [];
  for (const f of friendships) {
    const userResult = await dynamo.send(
      new GetCommand({ TableName: USERS_TABLE, Key: { userId: f.friendId } })
    );
    const profile = userResult.Item || {};
    enriched.push({
      friendId: f.friendId,
      displayName: profile.displayName || profile.email || "User",
      status: f.status,
      createdAt: f.createdAt,
    });
  }

  const accepted = enriched.filter(f => f.status === "accepted");
  const pendingReceived = enriched.filter(f => f.status === "pending_received");
  const pendingSent = enriched.filter(f => f.status === "pending_sent");

  return response(200, { accepted, pendingReceived, pendingSent });
}

async function acceptFriendRequest(userId, friendId) {
  // Update both sides to accepted
  await dynamo.send(
    new UpdateCommand({
      TableName: FRIENDSHIPS_TABLE,
      Key: { userId, friendId },
      UpdateExpression: "SET #s = :status",
      ExpressionAttributeNames: { "#s": "status" },
      ExpressionAttributeValues: { ":status": "accepted" },
    })
  );

  await dynamo.send(
    new UpdateCommand({
      TableName: FRIENDSHIPS_TABLE,
      Key: { userId: friendId, friendId: userId },
      UpdateExpression: "SET #s = :status",
      ExpressionAttributeNames: { "#s": "status" },
      ExpressionAttributeValues: { ":status": "accepted" },
    })
  );

  // Add to activity feed
  await addActivity(friendId, "friend_accepted", `Your friend request was accepted`, userId);

  return response(200, { message: "Friend request accepted" });
}

async function rejectFriendRequest(userId, friendId) {
  // Delete both sides
  await dynamo.send(
    new DeleteCommand({ TableName: FRIENDSHIPS_TABLE, Key: { userId, friendId } })
  );
  await dynamo.send(
    new DeleteCommand({ TableName: FRIENDSHIPS_TABLE, Key: { userId: friendId, friendId: userId } })
  );

  return response(200, { message: "Friend request rejected" });
}

async function removeFriend(userId, friendId) {
  await dynamo.send(
    new DeleteCommand({ TableName: FRIENDSHIPS_TABLE, Key: { userId, friendId } })
  );
  await dynamo.send(
    new DeleteCommand({ TableName: FRIENDSHIPS_TABLE, Key: { userId: friendId, friendId: userId } })
  );

  return response(200, { message: "Friend removed" });
}

// MARK: - Activity Feed

async function addActivity(userId, type, message, relatedUserId) {
  await dynamo.send(
    new PutCommand({
      TableName: ACTIVITY_TABLE,
      Item: {
        userId,
        timestamp: new Date().toISOString(),
        type,
        message,
        relatedUserId: relatedUserId || null,
      },
    })
  );
}

async function getActivityFeed(userId) {
  // Get user's own activity
  const result = await dynamo.send(
    new QueryCommand({
      TableName: ACTIVITY_TABLE,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: { ":uid": userId },
      ScanIndexForward: false,
      Limit: 20,
    })
  );

  // Also get activity of accepted friends
  const friendsResult = await dynamo.send(
    new QueryCommand({
      TableName: FRIENDSHIPS_TABLE,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: { ":uid": userId },
    })
  );

  const acceptedFriends = (friendsResult.Items || [])
    .filter(f => f.status === "accepted")
    .map(f => f.friendId);

  let friendActivity = [];
  for (const fId of acceptedFriends.slice(0, 10)) {
    const fResult = await dynamo.send(
      new QueryCommand({
        TableName: ACTIVITY_TABLE,
        KeyConditionExpression: "userId = :uid",
        ExpressionAttributeValues: { ":uid": fId },
        ScanIndexForward: false,
        Limit: 5,
      })
    );
    // Get friend's display name
    const userResult = await dynamo.send(
      new GetCommand({ TableName: USERS_TABLE, Key: { userId: fId } })
    );
    const name = userResult.Item?.displayName || "Friend";
    friendActivity.push(...(fResult.Items || []).map(a => ({ ...a, displayName: name })));
  }

  // Combine and sort by timestamp
  const allActivity = [...(result.Items || []), ...friendActivity]
    .sort((a, b) => b.timestamp.localeCompare(a.timestamp))
    .slice(0, 30);

  return response(200, { activity: allActivity });
}

// MARK: - Feedback

async function submitFeedback(userId, data) {
  const { type, title, description } = data;

  if (!title || !description) {
    return response(400, { error: "title and description are required" });
  }

  // Get user info for the email
  const userResult = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId } })
  );
  const userName = userResult.Item?.displayName || userResult.Item?.email || userId;

  // Send email
  try {
    await ses.send(new SendEmailCommand({
      Source: "louie@louie.cloud",
      Destination: {
        ToAddresses: ["louie@louie.cloud"],
      },
      Message: {
        Subject: {
          Data: `[Agon ${type}] ${title}`,
        },
        Body: {
          Text: {
            Data: `Type: ${type}\nFrom: ${userName} (${userId})\n\nTitle: ${title}\n\nDescription:\n${description}\n\nTimestamp: ${new Date().toISOString()}`,
          },
        },
      },
    }));
  } catch (emailError) {
    console.log("SES email failed (may not be configured):", emailError.message);
    // Still save feedback even if email fails
  }

  // Also store in activity for record
  await addActivity(userId, "feedback", `Submitted ${type}: ${title}`, null);

  return response(200, { message: "Feedback submitted successfully" });
}

// MARK: - Public Challenges & Trophies (Feature 1)

async function getPublicChallenges(userId) {
  // Get user's trophies to show which are already earned
  const userResult = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId } })
  );
  const trophies = userResult.Item?.trophies || [];
  const earnedIds = trophies.map((t) => t.challengeId);

  // Get user's joined public challenges
  const joinedChallenges = userResult.Item?.joinedPublicChallenges || [];

  // Calculate current week progress
  const today = new Date();
  const dayOfWeek = today.getUTCDay();
  const daysSinceMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  const monday = new Date(today.getTime() - daysSinceMonday * 24 * 60 * 60 * 1000);
  const startDate = monday.toISOString().split("T")[0];
  const endDate = today.toISOString().split("T")[0];

  let metricAverages = {};
  const snapshotsResult = await dynamo.send(
    new QueryCommand({
      TableName: HEALTH_SNAPSHOTS_TABLE,
      KeyConditionExpression: "userId = :userId AND #d BETWEEN :start AND :end",
      ExpressionAttributeNames: { "#d": "date" },
      ExpressionAttributeValues: {
        ":userId": userId,
        ":start": startDate,
        ":end": endDate,
      },
    })
  );

  const snapshots = snapshotsResult.Items || [];
  if (snapshots.length > 0) {
    const metricTotals = {};
    for (const snapshot of snapshots) {
      const metrics = snapshot.metrics || {};
      for (const [key, value] of Object.entries(metrics)) {
        metricTotals[key] = (metricTotals[key] || 0) + (value || 0);
      }
    }
    for (const [key, total] of Object.entries(metricTotals)) {
      metricAverages[key] = total / snapshots.length;
    }
  }

  const challenges = PUBLIC_CHALLENGES.map((c) => ({
    ...c,
    earned: earnedIds.includes(c.id),
    joined: joinedChallenges.includes(c.id),
    progress: Math.round((metricAverages[c.metric] || 0) * 100) / 100,
  }));

  return response(200, { challenges });
}

async function joinPublicChallenge(userId, challengeId) {
  if (!challengeId) {
    return response(400, { error: "challengeId is required" });
  }

  const challenge = PUBLIC_CHALLENGES.find((c) => c.id === challengeId);
  if (!challenge) {
    return response(404, { error: "Public challenge not found" });
  }

  // Add to user's joinedPublicChallenges array
  await dynamo.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: "SET joinedPublicChallenges = list_append(if_not_exists(joinedPublicChallenges, :empty), :challenge), updatedAt = :now",
      ExpressionAttributeValues: {
        ":challenge": [challengeId],
        ":empty": [],
        ":now": new Date().toISOString(),
      },
    })
  );

  return response(200, { message: "Joined public challenge", challengeId });
}

async function checkTrophies(userId) {
  // Get user's joined public challenges
  const userResult = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId } })
  );
  const joinedChallenges = userResult.Item?.joinedPublicChallenges || [];
  const existingTrophies = userResult.Item?.trophies || [];

  // Calculate current calendar week (Mon-Sun)
  const today = new Date();
  const dayOfWeek = today.getUTCDay(); // 0=Sun, 1=Mon...
  const daysSinceMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  const monday = new Date(today.getTime() - daysSinceMonday * 24 * 60 * 60 * 1000);
  const startDate = monday.toISOString().split("T")[0];
  const endDate = today.toISOString().split("T")[0];

  // Get week number and year
  const startOfYear = new Date(today.getFullYear(), 0, 1);
  const weekNumber = Math.ceil(((today - startOfYear) / 86400000 + startOfYear.getDay() + 1) / 7);
  const year = today.getFullYear();
  const weekId = `${year}-W${weekNumber}`;

  // Check which trophies already earned THIS week
  const earnedThisWeek = existingTrophies
    .filter((t) => t.weekId === weekId)
    .map((t) => t.challengeId);

  const snapshotsResult = await dynamo.send(
    new QueryCommand({
      TableName: HEALTH_SNAPSHOTS_TABLE,
      KeyConditionExpression: "userId = :userId AND #d BETWEEN :start AND :end",
      ExpressionAttributeNames: { "#d": "date" },
      ExpressionAttributeValues: {
        ":userId": userId,
        ":start": startDate,
        ":end": endDate,
      },
    })
  );

  const snapshots = snapshotsResult.Items || [];
  if (snapshots.length === 0) {
    return response(200, { newTrophies: [], totalTrophies: existingTrophies, weekId });
  }

  // Calculate daily averages for each metric
  const metricTotals = {};
  for (const snapshot of snapshots) {
    const metrics = snapshot.metrics || {};
    for (const [key, value] of Object.entries(metrics)) {
      metricTotals[key] = (metricTotals[key] || 0) + (value || 0);
    }
  }

  const numDays = snapshots.length;
  const metricAverages = {};
  for (const [key, total] of Object.entries(metricTotals)) {
    metricAverages[key] = total / numDays;
  }

  // Check which joined challenges are now completed THIS week
  const newTrophies = [];
  for (const challenge of PUBLIC_CHALLENGES) {
    // Only check challenges user has joined and hasn't already earned THIS WEEK
    if (!joinedChallenges.includes(challenge.id) || earnedThisWeek.includes(challenge.id)) {
      continue;
    }

    const average = metricAverages[challenge.metric] || 0;
    if (average >= challenge.target) {
      const trophy = {
        challengeId: challenge.id,
        title: challenge.title,
        tier: challenge.tier,
        metric: challenge.metric,
        target: challenge.target,
        achievedAverage: Math.round(average * 100) / 100,
        earnedAt: new Date().toISOString(),
        weekId,
        weekNumber,
        year,
      };
      newTrophies.push(trophy);
    }
  }

  // If there are new trophies, save them
  if (newTrophies.length > 0) {
    const allTrophies = [...existingTrophies, ...newTrophies];
    await dynamo.send(
      new UpdateCommand({
        TableName: USERS_TABLE,
        Key: { userId },
        UpdateExpression: "SET trophies = :trophies, updatedAt = :now",
        ExpressionAttributeValues: {
          ":trophies": allTrophies,
          ":now": new Date().toISOString(),
        },
      })
    );
    return response(200, { newTrophies, totalTrophies: allTrophies });
  }

  return response(200, { newTrophies: [], totalTrophies: existingTrophies });
}

async function getTrophies(targetUserId) {
  if (!targetUserId) {
    return response(400, { error: "userId is required" });
  }

  const result = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId: targetUserId } })
  );

  if (!result.Item) {
    return response(404, { error: "User not found" });
  }

  return response(200, { trophies: result.Item.trophies || [] });
}

// MARK: - Feed (Feature 5)

async function createFeedPost(userId, data) {
  const { type, title, body: postBody, metric, value } = data;

  if (!type || !title) {
    return response(400, { error: "type and title are required" });
  }

  const postId = randomUUID();
  const item = {
    postId,
    userId,
    type,
    title,
    body: postBody || null,
    metric: metric || null,
    value: value || null,
    likes: [],
    commentsCount: 0,
    timestamp: new Date().toISOString(),
  };

  await dynamo.send(
    new PutCommand({
      TableName: FEED_TABLE,
      Item: item,
    })
  );

  return response(201, item);
}

async function getFeed(userId) {
  // Get accepted friends
  const friendsResult = await dynamo.send(
    new QueryCommand({
      TableName: FRIENDSHIPS_TABLE,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: { ":uid": userId },
    })
  );

  const acceptedFriends = (friendsResult.Items || [])
    .filter((f) => f.status === "accepted")
    .map((f) => f.friendId);

  // Include user's own posts
  const allUserIds = [userId, ...acceptedFriends];

  // Get posts from each user via GSI
  let allPosts = [];
  for (const uid of allUserIds) {
    const postsResult = await dynamo.send(
      new QueryCommand({
        TableName: FEED_TABLE,
        IndexName: "userId-index",
        KeyConditionExpression: "userId = :uid",
        ExpressionAttributeValues: { ":uid": uid },
        ScanIndexForward: false,
        Limit: 10,
      })
    );
    allPosts.push(...(postsResult.Items || []));
  }

  // Sort by timestamp descending
  allPosts.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
  allPosts = allPosts.slice(0, 50);

  // Enrich with user display names
  const userCache = {};
  for (const post of allPosts) {
    if (!userCache[post.userId]) {
      const userResult = await dynamo.send(
        new GetCommand({ TableName: USERS_TABLE, Key: { userId: post.userId } })
      );
      userCache[post.userId] = userResult.Item || {};
    }
    post.displayName = userCache[post.userId].displayName || "Unknown";
    post.avatarUrl = userCache[post.userId].avatarUrl || null;
    post.likesCount = (post.likes || []).length;
    post.likedByMe = (post.likes || []).includes(userId);
  }

  return response(200, { posts: allPosts });
}

async function likeFeedPost(userId, postId) {
  if (!postId) {
    return response(400, { error: "postId is required" });
  }

  // Get the post
  const result = await dynamo.send(
    new GetCommand({ TableName: FEED_TABLE, Key: { postId } })
  );

  if (!result.Item) {
    return response(404, { error: "Post not found" });
  }

  const likes = result.Item.likes || [];
  let updatedLikes;

  if (likes.includes(userId)) {
    // Unlike
    updatedLikes = likes.filter((id) => id !== userId);
  } else {
    // Like
    updatedLikes = [...likes, userId];
  }

  await dynamo.send(
    new UpdateCommand({
      TableName: FEED_TABLE,
      Key: { postId },
      UpdateExpression: "SET likes = :likes",
      ExpressionAttributeValues: { ":likes": updatedLikes },
    })
  );

  return response(200, { liked: updatedLikes.includes(userId), likesCount: updatedLikes.length });
}

async function commentOnFeedPost(userId, postId, data) {
  if (!postId) {
    return response(400, { error: "postId is required" });
  }
  const { text } = data;
  if (!text) {
    return response(400, { error: "text is required" });
  }

  // Get the post to verify it exists
  const postResult = await dynamo.send(
    new GetCommand({ TableName: FEED_TABLE, Key: { postId } })
  );

  if (!postResult.Item) {
    return response(404, { error: "Post not found" });
  }

  // Store comment as a sub-item with postId as hash key and commentId as a sort key
  // We'll store comments in a `comments` list on the feed item
  const comment = {
    commentId: randomUUID(),
    userId,
    text,
    timestamp: new Date().toISOString(),
  };

  await dynamo.send(
    new UpdateCommand({
      TableName: FEED_TABLE,
      Key: { postId },
      UpdateExpression: "SET comments = list_append(if_not_exists(comments, :empty), :comment), commentsCount = if_not_exists(commentsCount, :zero) + :one",
      ExpressionAttributeValues: {
        ":comment": [comment],
        ":empty": [],
        ":zero": 0,
        ":one": 1,
      },
    })
  );

  return response(201, comment);
}

async function getFeedPostComments(postId) {
  if (!postId) {
    return response(400, { error: "postId is required" });
  }

  const result = await dynamo.send(
    new GetCommand({ TableName: FEED_TABLE, Key: { postId } })
  );

  if (!result.Item) {
    return response(404, { error: "Post not found" });
  }

  const comments = result.Item.comments || [];

  // Enrich with user display names
  const userCache = {};
  for (const comment of comments) {
    if (!userCache[comment.userId]) {
      const userResult = await dynamo.send(
        new GetCommand({ TableName: USERS_TABLE, Key: { userId: comment.userId } })
      );
      userCache[comment.userId] = userResult.Item || {};
    }
    comment.displayName = userCache[comment.userId].displayName || "Unknown";
    comment.avatarUrl = userCache[comment.userId].avatarUrl || null;
  }

  return response(200, { comments });
}

// MARK: - Rivals (Feature 6)

async function addRival(userId, data) {
  const { rivalId } = data;
  if (!rivalId) return response(400, { error: "rivalId is required" });
  if (rivalId === userId) return response(400, { error: "Cannot rival yourself" });

  // Verify rival user exists
  const rivalResult = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId: rivalId } })
  );
  if (!rivalResult.Item) {
    return response(404, { error: "User not found" });
  }

  // Get current user's rivals
  const userResult = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId } })
  );
  const currentRivals = userResult.Item?.rivals || [];

  if (currentRivals.includes(rivalId)) {
    return response(400, { error: "Already a rival" });
  }

  // Add to rivals array
  await dynamo.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: "SET rivals = list_append(if_not_exists(rivals, :empty), :rival), updatedAt = :now",
      ExpressionAttributeValues: {
        ":rival": [rivalId],
        ":empty": [],
        ":now": new Date().toISOString(),
      },
    })
  );

  return response(200, { message: "Rival added", rivalId });
}

async function getRivals(userId) {
  // Get user's rivals list
  const userResult = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId } })
  );
  const rivalIds = userResult.Item?.rivals || [];

  if (rivalIds.length === 0) {
    return response(200, { rivals: [] });
  }

  // Get recent stats for each rival
  const today = new Date();
  const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
  const startDate = sevenDaysAgo.toISOString().split("T")[0];
  const endDate = today.toISOString().split("T")[0];

  const rivals = [];
  for (const rivalId of rivalIds) {
    const rivalProfile = await dynamo.send(
      new GetCommand({ TableName: USERS_TABLE, Key: { userId: rivalId } })
    );

    const snapshotsResult = await dynamo.send(
      new QueryCommand({
        TableName: HEALTH_SNAPSHOTS_TABLE,
        KeyConditionExpression: "userId = :userId AND #d BETWEEN :start AND :end",
        ExpressionAttributeNames: { "#d": "date" },
        ExpressionAttributeValues: {
          ":userId": rivalId,
          ":start": startDate,
          ":end": endDate,
        },
      })
    );

    const snapshots = snapshotsResult.Items || [];
    // Calculate averages
    const metricTotals = {};
    for (const snapshot of snapshots) {
      const metrics = snapshot.metrics || {};
      for (const [key, value] of Object.entries(metrics)) {
        metricTotals[key] = (metricTotals[key] || 0) + (value || 0);
      }
    }
    const numDays = snapshots.length || 1;
    const averages = {};
    for (const [key, total] of Object.entries(metricTotals)) {
      averages[key] = Math.round((total / numDays) * 100) / 100;
    }

    rivals.push({
      userId: rivalId,
      displayName: rivalProfile.Item?.displayName || "Unknown",
      avatarUrl: rivalProfile.Item?.avatarUrl || null,
      recentAverages: averages,
      snapshotDays: snapshots.length,
    });
  }

  return response(200, { rivals });
}

async function removeRival(userId, rivalId) {
  if (!rivalId) return response(400, { error: "rivalId is required" });

  // Get current rivals
  const userResult = await dynamo.send(
    new GetCommand({ TableName: USERS_TABLE, Key: { userId } })
  );
  const currentRivals = userResult.Item?.rivals || [];

  if (!currentRivals.includes(rivalId)) {
    return response(400, { error: "Not a rival" });
  }

  const updatedRivals = currentRivals.filter((id) => id !== rivalId);

  await dynamo.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: "SET rivals = :rivals, updatedAt = :now",
      ExpressionAttributeValues: {
        ":rivals": updatedRivals,
        ":now": new Date().toISOString(),
      },
    })
  );

  return response(200, { message: "Rival removed", rivalId });
}

// MARK: - Helpers

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify(body),
  };
}
