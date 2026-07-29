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

# Feed table (Feature 5)
resource "aws_dynamodb_table" "feed" {
  name         = "agon-${var.environment}-feed"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "postId"

  attribute {
    name = "postId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  global_secondary_index {
    name            = "userId-index"
    hash_key        = "userId"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "timestamp-index"
    hash_key        = "timestamp"
    projection_type = "ALL"
  }

  tags = {
    Name = "agon-${var.environment}-feed"
  }
}

# Profile images bucket
resource "aws_s3_bucket" "profile_images" {
  bucket = "agon-${var.environment}-profile-images"

  tags = {
    Name = "agon-${var.environment}-profile-images"
  }
}

resource "aws_s3_bucket_public_access_block" "profile_images" {
  bucket = aws_s3_bucket.profile_images.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "profile_images_public_read" {
  bucket = aws_s3_bucket.profile_images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.profile_images.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.profile_images]
}
