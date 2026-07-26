const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  QueryCommand,
  ScanCommand,
  UpdateCommand,
} = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const USERS_TABLE = process.env.USERS_TABLE;
const HEALTH_SNAPSHOTS_TABLE = process.env.HEALTH_SNAPSHOTS_TABLE;
const CHALLENGES_TABLE = process.env.CHALLENGES_TABLE;

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
  const item = {
    userId,
    email: data.email || null,
    displayName: data.displayName || null,
    provider: data.provider || null,
    avatarUrl: data.avatarUrl || null,
    createdAt: data.createdAt || new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  await dynamo.send(
    new PutCommand({
      TableName: USERS_TABLE,
      Item: item,
    })
  );

  return response(200, item);
}

// MARK: - Health Sync

async function syncHealth(userId, data) {
  const date = data.date || new Date().toISOString().split("T")[0];

  const item = {
    userId,
    date,
    metrics: data.metrics || {},
    syncedAt: new Date().toISOString(),
  };

  await dynamo.send(
    new PutCommand({
      TableName: HEALTH_SNAPSHOTS_TABLE,
      Item: item,
    })
  );

  return response(200, { message: "Health data synced", date });
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

// MARK: - Challenges

async function createChallenge(userId, data) {
  const { metric, duration, invitedUserIds } = data;

  if (!metric || !duration) {
    return response(400, { error: "metric and duration are required" });
  }

  const validMetrics = ["steps", "exerciseMinutes", "distanceWalked"];
  if (!validMetrics.includes(metric)) {
    return response(400, { error: `metric must be one of: ${validMetrics.join(", ")}` });
  }

  const startDate = new Date().toISOString();
  const endDate = new Date(Date.now() + duration * 24 * 60 * 60 * 1000).toISOString();

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

  const challenges = Object.values(challengeMap).sort(
    (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
  );

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
