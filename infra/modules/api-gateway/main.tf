resource "aws_apigatewayv2_api" "main" {
  name          = "agon-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 3600
  }

  tags = {
    Name = "agon-${var.environment}-api"
  }
}

# Cognito Authorizer
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_apigatewayv2_api.main.id]
    issuer   = "https://cognito-idp.eu-west-2.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "health_check" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_profile" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /profile"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_users" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /users"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "update_profile" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "PUT /profile"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "upload_avatar" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /profile/avatar"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "save_goals" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "PUT /profile/goals"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_goals" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /profile/goals"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "sync_health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /health/sync"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "health_history" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health/history"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_leaderboard" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /leaderboard/{challengeId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "create_challenge" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /challenges"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "list_challenges" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /challenges"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "join_challenge" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /challenges/{challengeId}/join"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_challenge" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /challenges/{challengeId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "delete_challenge" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "DELETE /challenges/{challengeId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "leave_challenge" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /challenges/{challengeId}/leave"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_user_by_id" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /users/{userId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Friends routes
resource "aws_apigatewayv2_route" "send_friend_request" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /friends/request"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_friends" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /friends"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "accept_friend" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /friends/{friendId}/accept"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "reject_friend" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /friends/{friendId}/reject"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "remove_friend" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "DELETE /friends/{friendId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_activity" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /activity"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "submit_feedback" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /feedback"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Public Challenges routes (Feature 1)
resource "aws_apigatewayv2_route" "get_public_challenges" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /challenges/public"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "join_public_challenge" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /challenges/public/{challengeId}/join"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Trophies routes (Feature 1)
resource "aws_apigatewayv2_route" "check_trophies" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /trophies/check"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_trophies" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /trophies/{userId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Feed routes (Feature 5)
resource "aws_apigatewayv2_route" "create_feed_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /feed"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_feed" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /feed"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "like_feed_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /feed/{postId}/like"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "comment_feed_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /feed/{postId}/comment"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_feed_comments" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /feed/{postId}/comments"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Rivals routes (Feature 6)
resource "aws_apigatewayv2_route" "add_rival" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /rivals"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_rivals" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /rivals"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "remove_rival" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "DELETE /rivals/{rivalId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/agon-${var.environment}"
  retention_in_days = 14
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
