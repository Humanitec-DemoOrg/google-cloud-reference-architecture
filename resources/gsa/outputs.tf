output "email" {
  value     = var.iam_members == null || length(var.iam_members.resource_names) == 0 ? "" : google_service_account.gsa[0].email
}