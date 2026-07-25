variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "apple_services_id" {
  description = "Apple Services ID for Sign In with Apple"
  type        = string
  sensitive   = true
}

variable "apple_team_id" {
  description = "Apple Developer Team ID"
  type        = string
  sensitive   = true
}

variable "apple_key_id" {
  description = "Apple Sign In private key ID"
  type        = string
  sensitive   = true
}

variable "apple_private_key" {
  description = "Apple Sign In private key (PEM format)"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "Google OAuth Client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
  sensitive   = true
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment zip"
  type        = string
  default     = "../../../lambda/lambda.zip"
}
