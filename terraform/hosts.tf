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
    public_key = var.bootstrap_ssh_key
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

# Each host has a separate disk for nova ephemeral storage on lun10
resource "azurerm_managed_disk" "hosts_nova" {
  count               = length(var.hosts)
  name                = format("host-%02d-nova", count.index)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.nova_disk_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "hosts_nova" {
  count              = length(var.hosts)
  managed_disk_id    = azurerm_managed_disk.hosts_nova[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.hosts[count.index].id
  lun                = "10"
  caching            = "None"
}

# Each host has some number of extra disks specified in hosts.extra_disks
locals {
  extra_disks = flatten([
    for host_i, host in var.hosts : [
      for extra_disk_i, extra_disk in host.extra_disks : {
        host = host_i
        disk = extra_disk_i
        size = extra_disk
      }
    ]
  ])
}

resource "azurerm_managed_disk" "hosts_extra" {
  count               = length(local.extra_disks)
  name                = format("host-%02d-extra-%02d", local.extra_disks[count.index].host, local.extra_disks[count.index].disk)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = local.extra_disks[count.index].size
}

resource "azurerm_virtual_machine_data_disk_attachment" "hosts_extra" {
  count              = length(local.extra_disks)
  managed_disk_id    = azurerm_managed_disk.hosts_extra[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.hosts[local.extra_disks[count.index].host].id
  lun                = format("%d", 11 + local.extra_disks[count.index].disk)
  caching            = "None"
}
