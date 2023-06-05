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

##
## Variable definitions
##

# Environment name. Used for naming resources
variable "env_name" {
  default = "mbooth-test"
}

# Azure location where all resources will be created
variable "location" {
  default = "uksouth"
}

# A GitHub identity whose ssh key will be added to all VMs on creation
# Azurerm only seems to allow a single SSH key, so other keys will be added by
# ansible later.
variable "bootstrap_github_ssh_key" {
  default = "mdbooth"
}

# Address space of the internal vnet
# At least 2 /24 subnets will be created from this address space:
# * external is used only by the bastion
# * internal is used by OpenStack hosts
variable "address_space" {
  default = "192.168.224.0/21"
}

# OpenStack hosts to create
# Hosts will be named host-NN, starting from host-00
# All hosts will have an a 250G data disk for Nova ephemeral storage in
# addition to any disks defined in <extra_disks>.
# Host is defined as:
# {
#   size: <Azure Size>,
#   extra_disks: [<size in GB>, <size in GB>],
# }
variable "hosts" {
  type = list(object({
    size        = string
    extra_disks = list(number)
  }))
  default = [{
    size        = "Standard_E2as_v5"
    extra_disks = [500]
  }]
}

##
## Computed variables
##

data "curl" "bootstrap_github_ssh_key" {
  uri         = format("https://github.com/%s.keys", var.bootstrap_github_ssh_key)
  http_method = "GET"
}

locals {
  external_cidr     = cidrsubnet(var.address_space, 3, 0)
  internal_cidr     = cidrsubnet(var.address_space, 3, 1)
  bootstrap_ssh_key = data.curl.bootstrap_github_ssh_key.response
}

##
## Outputs
##

output "bastion_ip" {
  value = azurerm_public_ip.bastion.ip_address
}

output "hosts" {
  value = concat(
    [{
      name       = "bastion",
      private_ip = azurerm_network_interface.bastion_internal.private_ip_address
    }],
    [for i, interface in azurerm_network_interface.hosts : {
      name       = format("host-%02d", i)
      private_ip = interface.private_ip_address
    }]
  )
}

##
## Resource group contains all resources
##

resource "azurerm_resource_group" "rg" {
  name     = var.env_name
  location = var.location
}
