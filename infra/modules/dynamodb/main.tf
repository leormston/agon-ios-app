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
