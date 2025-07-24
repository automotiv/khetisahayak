# CDN Module Variables

variable "name_prefix" {
  description = "Name prefix for CDN resources"
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

variable "sku" {
  description = "The pricing tier (defines a CDN provider, feature list and rate) of the CDN Profile"
  type        = string
  default     = "Standard_Microsoft"
  validation {
    condition = contains([
      "Standard_Verizon", "Premium_Verizon", "Custom_Verizon", "Standard_Akamai",
      "Standard_ChinaCdn", "Standard_Microsoft", "Standard_AzureFrontDoor",
      "Premium_AzureFrontDoor", "Standard_955BandWidth_ChinaCdn"
    ], var.sku)
    error_message = "The sku must be a valid CDN profile SKU."
  }
}

variable "endpoints" {
  description = "Map of CDN endpoints to create"
  type = map(object({
    origin_host_header            = string
    origin_path                   = string
    querystring_caching_behaviour = string
    content_types_to_compress     = list(string)
    is_compression_enabled        = bool
    is_http_allowed              = bool
    is_https_allowed             = bool
    optimization_type            = string
    origins = list(object({
      name       = string
      host_name  = string
      http_port  = number
      https_port = number
    }))
    global_delivery_rule = object({
      cache_expiration_action = object({
        behavior = string
        duration = string
      })
      cache_key_query_string_action = object({
        behavior   = string
        parameters = string
      })
      modify_request_header_action = list(object({
        action = string
        name   = string
        value  = string
      }))
      modify_response_header_action = list(object({
        action = string
        name   = string
        value  = string
      }))
    })
    delivery_rules = list(object({
      name  = string
      order = number
      cache_expiration_action = object({
        behavior = string
        duration = string
      })
      cache_key_query_string_action = object({
        behavior   = string
        parameters = string
      })
      cookies_condition = list(object({
        selector         = string
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      device_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
      }))
      http_version_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
      }))
      modify_request_header_action = list(object({
        action = string
        name   = string
        value  = string
      }))
      modify_response_header_action = list(object({
        action = string
        name   = string
        value  = string
      }))
      post_arg_condition = list(object({
        selector         = string
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      query_string_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      remote_address_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
      }))
      request_body_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      request_header_condition = list(object({
        selector         = string
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      request_method_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
      }))
      request_scheme_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
      }))
      request_uri_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      url_file_extension_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      url_file_name_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      url_path_condition = list(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = list(string)
      }))
      url_redirect_action = object({
        redirect_type = string
        protocol      = string
        hostname      = string
        path          = string
        query_string  = string
        fragment      = string
      })
      url_rewrite_action = object({
        source_pattern          = string
        destination             = string
        preserve_unmatched_path = bool
      })
    }))
    geo_filters = list(object({
      relative_path = string
      action        = string
      country_codes = list(string)
    }))
  }))
  default = {}
}

variable "custom_domains" {
  description = "Map of custom domains to create"
  type = map(object({
    endpoint_name = string
    host_name     = string
    cdn_managed_https = object({
      certificate_type = string
      protocol_type    = string
      tls_version      = string
    })
    user_managed_https = object({
      key_vault_certificate_id = string
      key_vault_secret_id      = string
      tls_version              = string
    })
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
