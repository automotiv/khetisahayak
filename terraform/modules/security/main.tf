# Security Module for Kheti Sahayak

# Security Center Contact
resource "azurerm_security_center_contact" "main" {
  count = var.security_center_contact != null ? 1 : 0

  email               = var.security_center_contact.email
  phone               = var.security_center_contact.phone
  alert_notifications = var.security_center_contact.alert_notifications
  alerts_to_admins    = var.security_center_contact.alerts_to_admins
}

# Security Center Workspace
resource "azurerm_security_center_workspace" "main" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = var.log_analytics_workspace_id
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Network Security Groups
resource "azurerm_network_security_group" "nsg" {
  for_each = var.network_security_groups

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Network Security Rules
resource "azurerm_network_security_rule" "rules" {
  for_each = var.network_security_rules

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_port_ranges          = each.value.source_port_ranges
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  source_address_prefixes     = each.value.source_address_prefixes
  destination_address_prefixes = each.value.destination_address_prefixes
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.network_security_group_name].name
}

# Associate NSG with Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = var.nsg_subnet_associations

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "main" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "${var.name_prefix}-ddos"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "dns_zones" {
  for_each = toset(var.private_dns_zones)

  name                = each.value
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Private DNS Zone Virtual Network Links
resource "azurerm_private_dns_zone_virtual_network_link" "dns_links" {
  for_each = var.private_dns_zone_vnet_links

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zones[each.value.dns_zone_name].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled

  tags = var.tags
}

# Web Application Firewall Policy
resource "azurerm_web_application_firewall_policy" "waf" {
  count = var.waf_policy != null ? 1 : 0

  name                = "${var.name_prefix}-waf"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = var.waf_policy.enabled
    mode                        = var.waf_policy.mode
    request_body_check          = var.waf_policy.request_body_check
    file_upload_limit_in_mb     = var.waf_policy.file_upload_limit_in_mb
    max_request_body_size_in_kb = var.waf_policy.max_request_body_size_in_kb
  }

  dynamic "custom_rules" {
    for_each = var.waf_policy.custom_rules
    content {
      name      = custom_rules.value.name
      priority  = custom_rules.value.priority
      rule_type = custom_rules.value.rule_type
      action    = custom_rules.value.action

      dynamic "match_conditions" {
        for_each = custom_rules.value.match_conditions
        content {
          dynamic "match_variables" {
            for_each = match_conditions.value.match_variables
            content {
              variable_name = match_variables.value.variable_name
              selector      = match_variables.value.selector
            }
          }
          operator           = match_conditions.value.operator
          negation_condition = match_conditions.value.negation_condition
          match_values       = match_conditions.value.match_values
          transforms         = match_conditions.value.transforms
        }
      }
    }
  }

  dynamic "managed_rules" {
    for_each = var.waf_policy.managed_rules != null ? [var.waf_policy.managed_rules] : []
    content {
      dynamic "exclusion" {
        for_each = managed_rules.value.exclusions
        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator
        }
      }

      dynamic "managed_rule_set" {
        for_each = managed_rules.value.managed_rule_sets
        content {
          type    = managed_rule_set.value.type
          version = managed_rule_set.value.version

          dynamic "rule_group_override" {
            for_each = managed_rule_set.value.rule_group_overrides
            content {
              rule_group_name = rule_group_override.value.rule_group_name

              dynamic "rule" {
                for_each = rule_group_override.value.rules
                content {
                  id      = rule.value.id
                  enabled = rule.value.enabled
                  action  = rule.value.action
                }
              }
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  count = var.firewall_config != null ? 1 : 0

  name                = "${var.name_prefix}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.firewall_config.sku_name
  sku_tier            = var.firewall_config.sku_tier
  firewall_policy_id  = var.firewall_config.firewall_policy_id

  dynamic "ip_configuration" {
    for_each = var.firewall_config.ip_configurations
    content {
      name                 = ip_configuration.value.name
      subnet_id            = ip_configuration.value.subnet_id
      public_ip_address_id = ip_configuration.value.public_ip_address_id
    }
  }

  dynamic "management_ip_configuration" {
    for_each = var.firewall_config.management_ip_configuration != null ? [var.firewall_config.management_ip_configuration] : []
    content {
      name                 = management_ip_configuration.value.name
      subnet_id            = management_ip_configuration.value.subnet_id
      public_ip_address_id = management_ip_configuration.value.public_ip_address_id
    }
  }

  tags = var.tags
}

# Diagnostic Settings for NSGs
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  for_each = var.log_analytics_workspace_id != null ? var.network_security_groups : {}

  name                       = "${each.key}-diag"
  target_resource_id         = azurerm_network_security_group.nsg[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
