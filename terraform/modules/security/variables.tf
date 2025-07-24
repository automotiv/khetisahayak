# Security Module Variables

variable "name_prefix" {
  description = "Name prefix for security resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location for resources"
  type        = string
}

variable "security_center_contact" {
  description = "Security Center contact information"
  type = object({
    email               = string
    phone               = string
    alert_notifications = bool
    alerts_to_admins    = bool
  })
  default = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Security Center"
  type        = string
  default     = null
}

variable "network_security_groups" {
  description = "Map of Network Security Groups to create"
  type        = map(object({}))
  default     = {}
}

variable "network_security_rules" {
  description = "Map of Network Security Rules to create"
  type = map(object({
    network_security_group_name  = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = string
    destination_port_range       = string
    source_port_ranges           = list(string)
    destination_port_ranges      = list(string)
    source_address_prefix        = string
    destination_address_prefix   = string
    source_address_prefixes      = list(string)
    destination_address_prefixes = list(string)
  }))
  default = {}
}

variable "nsg_subnet_associations" {
  description = "Map of NSG to subnet associations"
  type        = map(string)
  default     = {}
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Plan"
  type        = bool
  default     = false
}

variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type        = list(string)
  default     = []
}

variable "private_dns_zone_vnet_links" {
  description = "Map of private DNS zone virtual network links"
  type = map(object({
    dns_zone_name        = string
    virtual_network_id   = string
    registration_enabled = bool
  }))
  default = {}
}

variable "waf_policy" {
  description = "Web Application Firewall policy configuration"
  type = object({
    enabled                     = bool
    mode                        = string
    request_body_check          = bool
    file_upload_limit_in_mb     = number
    max_request_body_size_in_kb = number
    custom_rules = list(object({
      name      = string
      priority  = number
      rule_type = string
      action    = string
      match_conditions = list(object({
        match_variables = list(object({
          variable_name = string
          selector      = string
        }))
        operator           = string
        negation_condition = bool
        match_values       = list(string)
        transforms         = list(string)
      }))
    }))
    managed_rules = object({
      exclusions = list(object({
        match_variable          = string
        selector                = string
        selector_match_operator = string
      }))
      managed_rule_sets = list(object({
        type    = string
        version = string
        rule_group_overrides = list(object({
          rule_group_name = string
          rules = list(object({
            id      = string
            enabled = bool
            action  = string
          }))
        }))
      }))
    })
  })
  default = null
}

variable "firewall_config" {
  description = "Azure Firewall configuration"
  type = object({
    sku_name           = string
    sku_tier           = string
    firewall_policy_id = string
    ip_configurations = list(object({
      name                 = string
      subnet_id            = string
      public_ip_address_id = string
    }))
    management_ip_configuration = object({
      name                 = string
      subnet_id            = string
      public_ip_address_id = string
    })
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
