resource_group_name = "rg-aks-platform"
location            = "Australia Central"
cluster_name        = "aks-platform"
dns_prefix          = "aks-platform"
kubernetes_version  = "1.30"
node_count          = 3
node_vm_size        = "Standard_D4s_v5"
tenant_id           = "00000000-0000-0000-0000-000000000000"

tags = {
  workload    = "platform"
  environment = "shared"
  managed-by  = "terraform"
}
