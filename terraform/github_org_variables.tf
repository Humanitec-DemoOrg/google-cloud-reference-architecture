# https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable

resource "github_actions_organization_variable" "org_cloud_provider" {
  count             = var.humanitec_env_type == "development" && var.github_create_org_secrets ? 1 : 0
  visibility        = "all"
  variable_name     = "CLOUD_PROVIDER"
  value             = "google-cloud"
}