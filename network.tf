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
    name                         = "ssh"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    destination_port_range       = 22
    destination_address_prefixes = azurerm_subnet.external.address_prefixes
    source_port_range            = "*"
    source_address_prefix        = "*"
  }

  security_rule {
    name                         = "wireguard"
    priority                     = 101
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Udp"
    destination_port_range       = 51820
    destination_address_prefixes = azurerm_subnet.external.address_prefixes
    source_port_range            = "*"
    source_address_prefix        = "*"
  }
}

resource "azurerm_network_security_group" "internal" {
  name                = "internal"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # External inbound traffic is not permitted
}
