variable "environment" {
  type = string
}

variable "apple_services_id" {
  type      = string
  sensitive = true
}

variable "apple_team_id" {
  type      = string
  sensitive = true
}

variable "apple_key_id" {
  type      = string
  sensitive = true
}

variable "apple_private_key" {
  type      = string
  sensitive = true
}

variable "google_client_id" {
  type      = string
  sensitive = true
}

variable "google_client_secret" {
  type      = string
  sensitive = true
}
