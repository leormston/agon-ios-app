output "users_table_name" {
  value = aws_dynamodb_table.users.name
}

output "users_table_arn" {
  value = aws_dynamodb_table.users.arn
}

output "health_snapshots_table_name" {
  value = aws_dynamodb_table.health_snapshots.name
}

output "health_snapshots_table_arn" {
  value = aws_dynamodb_table.health_snapshots.arn
}

output "challenges_table_name" {
  value = aws_dynamodb_table.challenges.name
}

output "challenges_table_arn" {
  value = aws_dynamodb_table.challenges.arn
}
