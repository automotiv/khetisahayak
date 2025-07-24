# Container Instance Module - Alternative to App Service
# This module creates Azure Container Instances which typically have fewer quota restrictions

resource "azurerm_container_group" "main" {
  name                = "${var.name_prefix}-cg"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  restart_policy      = "Always"

  container {
    name   = "${var.name_prefix}-container"
    image  = var.docker_image
    cpu    = var.cpu_cores
    memory = var.memory_gb

    ports {
      port     = var.container_port
      protocol = "TCP"
    }

    environment_variables = var.environment_variables
  }

  # Registry credentials for private registries
  dynamic "image_registry_credential" {
    for_each = var.registry_server != null ? [1] : []
    content {
      server   = var.registry_server
      username = var.registry_username
      password = var.registry_password
    }
  }

  ip_address_type = "Public"

  exposed_port {
    port     = var.container_port
    protocol = "TCP"
  }

  tags = var.tags
}
