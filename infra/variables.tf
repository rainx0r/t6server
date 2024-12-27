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
