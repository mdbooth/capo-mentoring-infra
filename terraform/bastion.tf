# Public IP of the bastion host
# This is the only static public IP
resource "azurerm_public_ip" "bastion" {
  name                = "bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

# External interface of bastion host
# Incoming SSH and wireguard allowed on this interface
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

# Internal interface of bastion host
resource "azurerm_network_interface" "bastion_internal" {
  name                = "bastion-internal"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "bastion_external" {
  network_interface_id      = azurerm_network_interface.bastion_external.id
  network_security_group_id = azurerm_network_security_group.external.id
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name = "bastion"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Allegedly Azure's smallest VM size
  size = "Standard_B1ls"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username = var.ssh_user
  admin_ssh_key {
    username   = var.ssh_user
    public_key = var.bootstrap_ssh_key
  }

  network_interface_ids = [
    azurerm_network_interface.bastion_external.id,
    azurerm_network_interface.bastion_internal.id
  ]

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }
}
