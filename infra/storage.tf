resource "azurerm_storage_account" "sa" {
  name                     = var.sa_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "game_files" {
  name                  = "game-files"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "setup_bat" {
  name                   = "setup.bat"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/../t6/setup.bat"
}

resource "azurerm_storage_blob" "start_bat" {
  name                   = "start.bat"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/../t6/start.bat"
}

resource "azurerm_storage_blob" "t6_zip" {
  name                   = "t6.zip"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.game_files.name
  type                   = "Block"
  source                 = "${path.module}/../.secrets/t6.zip"
}

output "setup_bat_url" {
  value = azurerm_storage_blob.setup_bat.url
}

output "start_bat_url" {
  value = azurerm_storage_blob.start_bat.url
}
