variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "aks_subnet_cidr" {
  type = list(string)
}

variable "appgw_subnet_cidr" {
  type = list(string)
}
