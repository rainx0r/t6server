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

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.sku
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "vm_blob_data_reader" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_virtual_machine.vm.identity[0].principal_id
}

resource "azurerm_virtual_machine_extension" "setup_server" {
  name                 = "run-setup-ps1"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = jsonencode({
    "commandToExecute" : "powershell.exe -ExecutionPolicy Unrestricted -File setup.ps1 -serverName \"${var.server_name}\" -serverKey \"${var.server_key}\" -serverPassword \"${var.server_password}\" -serverRconPassword \"${var.rcon_password}\"",
    "managedIdentity" : {}
  })

  settings = jsonencode({
    "fileUris" : [
      "${azurerm_storage_blob.setup_ps1.url}",
      "${azurerm_storage_blob.t6_zip.url}",
      "${azurerm_storage_blob.start_bat.url}",
      "${azurerm_storage_blob.server_cfg.url}"
    ],
  })
}
