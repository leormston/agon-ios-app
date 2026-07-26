const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  QueryCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const USERS_TABLE = process.env.USERS_TABLE;
const HEALTH_SNAPSHOTS_TABLE = process.env.HEALTH_SNAPSHOTS_TABLE;

exports.handler = async (event) => {
  const { routeKey, body, requestContext, pathParameters } = event;
  const userId = requestContext?.authorizer?.jwt?.claims?.sub;

  try {
    switch (routeKey) {
      case "GET /health":
        return response(200, { status: "ok", service: "agon-api", timestamp: new Date().toISOString() });

      case "GET /profile":
        return await getProfile(userId);

      case "PUT /profile":
        return await updateProfile(userId, JSON.parse(body));

      case "POST /health/sync":
        return await syncHealth(userId, JSON.parse(body));

      case "GET /leaderboard/{challengeId}":
        const challengeId = pathParameters?.challengeId;
        return await getLeaderboard(challengeId, userId);

      default:
        return response(404, { error: "Route not found" });
    }
  } catch (error) {
    console.error("Error:", error);
    return response(500, { error: "Internal server error" });
  }
};

// MARK: - Profile

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
