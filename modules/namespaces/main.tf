resource "kubernetes_namespace" "env" {
  for_each = toset(var.environments)

  metadata {
    name = each.value

    labels = {
      environment = each.value
      managed-by  = "terraform"
    }
  }
}
