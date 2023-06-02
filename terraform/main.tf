# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }

    curl = {
      source  = "anschoewe/curl"
      version = "~> 1.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

provider "curl" {}

resource "azurerm_resource_group" "rg" {
  name     = var.env_name
  location = var.location
}
