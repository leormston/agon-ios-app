variable "environment" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "health_snapshots_table_arn" {
  type = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment zip"
  type        = string
}
