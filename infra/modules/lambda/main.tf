data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "agon-${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# DynamoDB access policy
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*",
      var.health_snapshots_table_arn,
      "${var.health_snapshots_table_arn}/index/*",
      var.challenges_table_arn,
      "${var.challenges_table_arn}/index/*",
      var.friendships_table_arn,
      "${var.friendships_table_arn}/index/*",
      var.activity_table_arn,
      "${var.activity_table_arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "dynamodb-access"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

# S3 access for profile images
data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${var.profile_images_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "s3-access"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# SES send email
data "aws_iam_policy_document" "ses_access" {
  statement {
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ses_access" {
  name   = "ses-access"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.ses_access.json
}

# CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "api" {
  function_name = "agon-${var.environment}-api"
  role          = aws_iam_role.lambda.arn
  handler       = "src/index.handler"
  runtime       = "nodejs20.x"
  architectures = ["arm64"]
  timeout       = 30
  memory_size   = 256

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  environment {
    variables = {
      ENVIRONMENT            = var.environment
      USERS_TABLE            = "agon-${var.environment}-users"
      HEALTH_SNAPSHOTS_TABLE = "agon-${var.environment}-health-snapshots"
      CHALLENGES_TABLE       = "agon-${var.environment}-challenges"
      FRIENDSHIPS_TABLE      = "agon-${var.environment}-friendships"
      ACTIVITY_TABLE         = "agon-${var.environment}-activity"
      PROFILE_IMAGES_BUCKET  = "agon-${var.environment}-profile-images"
    }
  }

  tags = {
    Name = "agon-${var.environment}-api"
  }
}
