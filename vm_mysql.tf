resource "azurerm_storage_account" "storemyslq" {
  name                     = "storemyslq"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_linux_virtual_machine" "vm_mysql" {
  name                  = "vm_mysql"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.inet.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "mysqlDisc"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm-linux"
  admin_username                  = var.user
  admin_password                  = var.password
  disable_password_authentication = false

  depends_on = [azurerm_resource_group.rg, azurerm_network_interface.inet, azurerm_storage_account.storemyslq, azurerm_public_ip.publicip]
}

resource "time_sleep" "wait_30_seconds_db" {
  depends_on      = [azurerm_linux_virtual_machine.vm_mysql]
  create_duration = "30s"
}

resource "null_resource" "upload_mysql" {
  provisioner "file" {
    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = data.azurerm_public_ip.ip_data_db.ip_address
    }
    source      = "mysql"
    destination = "/home/azureuser"
  }

  depends_on = [time_sleep.wait_30_seconds_db]
}

resource "null_resource" "deploy_mysql" {
  triggers = {
    order = null_resource.upload_mysql.id
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = data.azurerm_public_ip.ip_data_db.ip_address
    }
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y mysql-server-5.7",
      "sudo cp -f /home/azureuser/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf",
      "sudo service mysql restart",
      "sleep 20",
    ]
  }
}