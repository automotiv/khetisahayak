# Container Registry Module for Kheti Sahayak

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.name_prefix, "-", "")}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags
}
