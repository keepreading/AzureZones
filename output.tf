output "ip_address" {
  value = "${azurerm_public_ip.pip.ip_address}"
}
output "fqdn_zone1" {
  value = "${azurerm_public_ip.pip.fqdn}"
}

output "ip_address2" {
  value = "${azurerm_public_ip.pip2.ip_address}"
}
output "fqdn_zone2" {
  value = "${azurerm_public_ip.pip2.fqdn}"
}
output "ip_address3" {
  value = "${azurerm_public_ip.pip3.ip_address}"
}
output "fqdn_zone3" {
  value = "${azurerm_public_ip.pip3.fqdn}"
}