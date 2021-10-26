resource "azurerm_network_interface" "inet" {
  name                = "inet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "sg_association" {
  network_interface_id      = azurerm_network_interface.inet.id
  network_security_group_id = azurerm_network_security_group.sg.id
}

data "azurerm_public_ip" "ip_data_db" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_resource_group.rg.name
}