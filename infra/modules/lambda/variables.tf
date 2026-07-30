variable "environment" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "health_snapshots_table_arn" {
  type = string
}

variable "challenges_table_arn" {
  type = string
}

variable "friendships_table_arn" {
  type = string
}

variable "activity_table_arn" {
  type = string
}

variable "feed_table_arn" {
  type = string
}

variable "profile_images_bucket_arn" {
  type = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment zip"
  type        = string
}
