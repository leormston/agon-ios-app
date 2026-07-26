output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.client_id
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.api_url
}

output "users_table_name" {
  description = "DynamoDB Users table name"
  value       = module.dynamodb.users_table_name
}

output "health_snapshots_table_name" {
  description = "DynamoDB Health Snapshots table name"
  value       = module.dynamodb.health_snapshots_table_name
}

output "challenges_table_name" {
  description = "DynamoDB Challenges table name"
  value       = module.dynamodb.challenges_table_name
}
