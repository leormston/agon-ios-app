# Users table
resource "aws_dynamodb_table" "users" {
  name         = "agon-${var.environment}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
  }

  tags = {
    Name = "agon-${var.environment}-users"
  }
}

# Health Snapshots table
resource "aws_dynamodb_table" "health_snapshots" {
  name         = "agon-${var.environment}-health-snapshots"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "date"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  tags = {
    Name = "agon-${var.environment}-health-snapshots"
  }
}

# Challenges table
resource "aws_dynamodb_table" "challenges" {
  name         = "agon-${var.environment}-challenges"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "challengeId"

  attribute {
    name = "challengeId"
    type = "S"
  }

  attribute {
    name = "creatorId"
    type = "S"
  }

  global_secondary_index {
    name            = "creatorId-index"
    hash_key        = "creatorId"
    projection_type = "ALL"
  }

  tags = {
    Name = "agon-${var.environment}-challenges"
  }
}

# Friendships table
resource "aws_dynamodb_table" "friendships" {
  name         = "agon-${var.environment}-friendships"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "friendId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "friendId"
    type = "S"
  }

  global_secondary_index {
    name            = "friendId-index"
    hash_key        = "friendId"
    range_key       = "userId"
    projection_type = "ALL"
  }

  tags = {
    Name = "agon-${var.environment}-friendships"
  }
}

# Activity feed table
resource "aws_dynamodb_table" "activity" {
  name         = "agon-${var.environment}-activity"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "timestamp"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Name = "agon-${var.environment}-activity"
  }
}
