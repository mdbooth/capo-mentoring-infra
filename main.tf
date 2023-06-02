# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

variable "env_name" {
  default = "mbooth-test"
}

variable "location" {
  default = "uksouth"
}

variable "bootstrap_ssh_key" {
  default = "~/.ssh/id_rsa_yubikey.pub"
}

variable "address_space" {
  default = "192.168.224.0/21"
}

locals {
  external_cidr = cidrsubnet(var.address_space, 3, 0)
  internal_cidr = cidrsubnet(var.address_space, 3, 1)
}

resource "azurerm_resource_group" "rg" {
  name     = var.env_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.env_name
  address_space       = [var.address_space]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "external" {
  name                 = "external"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.external_cidr]
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.internal_cidr]
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "external" {
  name                = "external"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                   = "ssh"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    destination_port_range = 22
    destination_address_prefixes = azurerm_subnet.external.address_prefixes
    source_port_range      = "*"
    source_address_prefix  = "*"
  }

  security_rule {
    name                   = "wireguard"
    priority               = 101
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Udp"
    destination_port_range = 51820
    destination_address_prefixes = azurerm_subnet.external.address_prefixes
    source_port_range      = "*"
    source_address_prefix  = "*"
  }
}

resource "azurerm_network_security_group" "internal" {
  name                = "internal"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # External inbound traffic is not permitted
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

output "bastion_ip" {
  value = azurerm_public_ip.bastion.ip_address
}

resource "azurerm_network_interface" "bastion_external" {
  name                = "bastion-external"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "external"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_network_interface" "bastion_internal" {
  name                = "bastion-internal"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name = "bastion"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Allegedly Azure's smallest VM size
  size = "Standard_B1ls"

  admin_username = "cloud"

  admin_ssh_key {
    username   = "cloud"
    public_key = file(var.bootstrap_ssh_key)
  }

  network_interface_ids = [
    azurerm_network_interface.bastion_external.id,
    azurerm_network_interface.bastion_internal.id
  ]

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
