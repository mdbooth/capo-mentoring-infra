output "bastion_ip" {
  value = azurerm_public_ip.bastion.ip_address
}

output "hosts" {
  value = [for i, interface in azurerm_network_interface.hosts : {
    name = format("host-%02d", i)
    ip   = interface.private_ip_address
  }]
}