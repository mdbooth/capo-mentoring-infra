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
## Variable definitions. Set by ansible.
##

# Environment name. Used for naming resources
variable "env_name" {}

# Azure location where all resources will be created
variable "location" {}

# ssh_user is the default user we create with ssh login via key and sudo access
variable "ssh_user" {}

# Address space of the internal vnet
# At least 2 /24 subnets will be created from this address space:
# * external is used only by the bastion
# * internal is used by OpenStack hosts
variable "vnet_address_space" {}

# A /24 subnet within vnet_address_space used by the bastion
variable "external_cidr" {}

# A /24 subnet within vnet_address_space used by all hosts
variable "internal_cidr" {}

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

# The size in GB of an external disk attached to each host VM for nova
# ephemeral storage
variable "nova_disk_size" {}

# An SSH key to add to all VMs on creation
# Other keys will be added by ansible subsequently
variable "bootstrap_ssh_key" {}

##
## Outputs
##

output "bastion" {
  value = {
    name       = "bastion",
    public_ip  = azurerm_public_ip.bastion.ip_address
    private_ip = azurerm_network_interface.bastion_internal.private_ip_address
  }
}

output "hosts" {
  value = [for i, interface in azurerm_network_interface.hosts : {
    name       = format("host-%02d", i)
    private_ip = interface.private_ip_address
  }]
}

##
## Resource group contains all resources
##

resource "azurerm_resource_group" "rg" {
  name     = var.env_name
  location = var.location
}
