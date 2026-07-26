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

output "friendships_table_name" {
  value = aws_dynamodb_table.friendships.name
}

output "friendships_table_arn" {
  value = aws_dynamodb_table.friendships.arn
}

output "activity_table_name" {
  value = aws_dynamodb_table.activity.name
}

output "activity_table_arn" {
  value = aws_dynamodb_table.activity.arn
}
