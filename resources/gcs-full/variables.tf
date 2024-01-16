variable "credentials" {
  description = "The credentials for connecting to Google Cloud."
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "The ID of the Google Cloud Project."
  type        = string
}

variable "region" {
  description = "The region of the GCS bucket."
  type        = string
}