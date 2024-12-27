resource "azurerm_storage_account" "sa" {
  name                     = "storage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "install_bat" {
  name                   = "install.bat"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = file("${path.module}/../t6/setup.bat")
}

resource "azurerm_storage_blob" "start_bat" {
  name                   = "start.bat"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = file("${path.module}/../t6/start.bat")
}

# We'll output the blob URL so we can pass it to the extension
output "setup_bat_url" {
  value = azurerm_storage_blob.setup_bat.url
}

output "start_bat_url" {
  value = azurerm_storage_blob.start_bat.url
}
