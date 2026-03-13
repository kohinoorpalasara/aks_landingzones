output "namespaces" {
  value = [for namespace in kubernetes_namespace.env : namespace.metadata[0].name]
}
