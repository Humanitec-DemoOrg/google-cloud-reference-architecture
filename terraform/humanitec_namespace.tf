# https://registry.terraform.io/providers/humanitec/humanitec/latest/docs/resources/resource_definition
resource "humanitec_resource_definition" "namespace" {
  count       = var.humanitec_env_type == "development" ? 1 : 0
  id          = "custom-namespace"
  name        = "custom-namespace"
  type        = "k8s-namespace"
  driver_type = "humanitec/template"

  driver_inputs = {
    values_string = jsonencode({
      templates = {
        init      = "name: $${context.env.id}-$${context.app.id}"
        manifests = <<EOL
namespace.yaml:
  location: cluster
  data:
    apiVersion: v1
    kind: Namespace
    metadata:
      name: {{ .init.name }}
EOL
        outputs   = "namespace: {{ .init.name }}"
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "namespace" {
  count                   = var.humanitec_env_type == "development" ? 1 : 0
  resource_definition_id  = humanitec_resource_definition.namespace[count.index].id
}