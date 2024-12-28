variable "rg_name" {
  type    = string
  default = "T6"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "vm_size" {
  type = string
  # Standard_ or Basic_
  # A1v2 for testing
  default = "Standard_A1v2"
}

variable "sku" {
  type = string
  default = "2022-datacenter-azure-edition"
}

variable "vm_password" {
  type = string
  sensitive = true
}

variable "subscription_id" {
  type = string
  sensitive = true
}

variable "sa_name" {
  type = string
}
