resource "azurerm_windows_virtual_machine" "vm" {
  name                = "moon-base"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = "edwardrichtofen"
  admin_password      = var.vm_password
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # admin_ssh_key {
  #  username   = "edwardrichtofen"
  #  public_key = file("${path.module}/../.secrets/id_ed5519.pub")
  #}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "run_setup_bat" {
  name                 = "run-setup-bat"
  virtual_machine_id   = azurerm_windows_virtual_machine
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
    "fileUris": [
      "${azurerm_storage_blob.setup_bat.url}"
    ],
    "commandToExecute": "cmd /c setup.bat"
  }
  SETTINGS
}
