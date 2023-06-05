# Note that per-host resources each use:
#   count = length(var.hosts)
# to create multiple resources. Dependencies are resolved by using the required
# resource by name in the dependent resource.

# Each host has a dynamic public ip
# This is only here so we don't need to do NAT for outgoing internet traffic.
# All incoming traffic is blocked by security group.
# We can remove these IPs if we find a better way to achieve this.
resource "azurerm_public_ip" "hosts" {
  count               = length(var.hosts)
  name                = format("host-%02d", count.index)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Each host has an interface on the internal network
resource "azurerm_network_interface" "hosts" {
  count               = length(var.hosts)
  name                = format("host-%02d", count.index)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hosts[count.index].id
  }
}

# Associate internal security group to deny all incoming traffic.
resource "azurerm_network_interface_security_group_association" "hosts" {
  count                     = length(var.hosts)
  network_interface_id      = azurerm_network_interface.hosts[count.index].id
  network_security_group_id = azurerm_network_security_group.internal.id
}

resource "azurerm_linux_virtual_machine" "hosts" {
  count               = length(var.hosts)
  name                = format("host-%02d", count.index)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size = var.hosts[count.index].size

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username = var.ssh_user
  admin_ssh_key {
    username   = var.ssh_user
    public_key = local.bootstrap_ssh_key
  }

  network_interface_ids = [
    azurerm_network_interface.hosts[count.index].id,
  ]

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }
}
