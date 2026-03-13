locals {
  environments = ["dev", "sit", "svt", "nfr", "prod"]
}

resource "azurerm_resource_group" "platform" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source = "../../modules/vnet"

  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  name                = "${var.cluster_name}-vnet"
  address_space       = ["10.10.0.0/16"]
  aks_subnet_cidr     = ["10.10.1.0/24"]
  appgw_subnet_cidr   = ["10.10.2.0/24"]
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  name                = "${var.cluster_name}-law"
  retention_in_days   = 30
}

module "acr" {
  source = "../../modules/acr"

  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  name                = replace("${var.cluster_name}acr", "-", "")
  sku                 = "Premium"
}

module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  name                = "${var.cluster_name}-kv"
  tenant_id           = var.tenant_id
}

module "aks" {
  source = "../../modules/aks"

  resource_group_name         = azurerm_resource_group.platform.name
  location                    = var.location
  cluster_name                = var.cluster_name
  dns_prefix                  = var.dns_prefix
  kubernetes_version          = var.kubernetes_version
  node_count                  = var.node_count
  vm_size                     = var.node_vm_size
  subnet_id                   = module.vnet.aks_subnet_id
  app_gateway_subnet_id       = module.vnet.appgw_subnet_id
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  acr_id                      = module.acr.id
  tags                        = var.tags
}

provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

module "namespaces" {
  source = "../../modules/namespaces"

  environments = local.environments

  providers = {
    kubernetes = kubernetes
  }
}

output "cluster_name" {
  value = module.aks.cluster_name
}

output "key_vault_uri" {
  value = module.keyvault.vault_uri
}

output "container_registry" {
  value = module.acr.login_server
}
