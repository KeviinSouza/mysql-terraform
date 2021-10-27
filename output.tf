output "out" {
  value = [azurerm_public_ip.publicip.ip_address, var.user, var.password]
}