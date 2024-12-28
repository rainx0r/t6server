terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.10.0"
    }
  }

  required_version = ">= 1.10.3"
}

provider "azurerm" {
  features {}
}
