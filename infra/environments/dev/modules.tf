module "cognito" {
  source = "../../modules/cognito"

  environment        = var.environment
  apple_services_id  = var.apple_services_id
  apple_team_id      = var.apple_team_id
  apple_key_id       = var.apple_key_id
  apple_private_key  = var.apple_private_key
  google_client_id   = var.google_client_id
  google_client_secret = var.google_client_secret
}

module "dynamodb" {
  source = "../../modules/dynamodb"

  environment = var.environment
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  environment           = var.environment
  cognito_user_pool_id  = module.cognito.user_pool_id
  lambda_invoke_arn     = module.lambda.invoke_arn
  lambda_function_name  = module.lambda.function_name
}

module "lambda" {
  source = "../../modules/lambda"

  environment                = var.environment
  dynamodb_table_arn         = module.dynamodb.users_table_arn
  health_snapshots_table_arn = module.dynamodb.health_snapshots_table_arn
  challenges_table_arn       = module.dynamodb.challenges_table_arn
  friendships_table_arn      = module.dynamodb.friendships_table_arn
  activity_table_arn         = module.dynamodb.activity_table_arn
  profile_images_bucket_arn  = module.dynamodb.profile_images_bucket_arn
  lambda_zip_path            = var.lambda_zip_path
}
