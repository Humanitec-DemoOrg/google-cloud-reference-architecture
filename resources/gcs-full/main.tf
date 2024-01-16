resource "random_string" "bucket_name" {
  length  = 10
  special = false
  lower   = true
  upper   = false
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "bucket" {
  name          = random_string.bucket_name.result
  location      = var.region
  force_destroy = true
}