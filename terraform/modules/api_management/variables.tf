# API Management Module Variables

variable "name_prefix" {
  description = "Name prefix for API Management resources"
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

variable "publisher_name" {
  description = "The name of publisher/company"
  type        = string
}

variable "publisher_email" {
  description = "The email of publisher/company"
  type        = string
}

variable "sku_name" {
  description = "The SKU of API Management service"
  type        = string
  default     = "Developer_1"
}

variable "public_ip_address_id" {
  description = "ID of a standard SKU IPv4 Public IP"
  type        = string
  default     = null
}

variable "virtual_network_configuration" {
  description = "Virtual network configuration"
  type = object({
    subnet_id = string
  })
  default = null
}

variable "additional_locations" {
  description = "List of additional datacenter locations of the API Management service"
  type = list(object({
    location             = string
    capacity             = number
    zones                = list(string)
    public_ip_address_id = string
    virtual_network_configuration = object({
      subnet_id = string
    })
  }))
  default = []
}

variable "security" {
  description = "Security configuration"
  type = object({
    enable_backend_ssl30                                = bool
    enable_backend_tls10                                = bool
    enable_backend_tls11                                = bool
    enable_frontend_ssl30                               = bool
    enable_frontend_tls10                               = bool
    enable_frontend_tls11                               = bool
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = bool
    tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = bool
    tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = bool
    tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = bool
    tls_rsa_with_aes128_cbc_sha256_ciphers_enabled     = bool
    tls_rsa_with_aes128_cbc_sha_ciphers_enabled        = bool
    tls_rsa_with_aes128_gcm_sha256_ciphers_enabled     = bool
    tls_rsa_with_aes256_cbc_sha256_ciphers_enabled     = bool
    tls_rsa_with_aes256_cbc_sha_ciphers_enabled        = bool
    tls_rsa_with_aes256_gcm_sha384_ciphers_enabled     = bool
    triple_des_ciphers_enabled                          = bool
  })
  default = null
}

variable "protocols" {
  description = "Protocols configuration"
  type = object({
    enable_http2 = bool
  })
  default = null
}

variable "identity" {
  description = "Managed identity configuration"
  type = object({
    type         = string
    identity_ids = list(string)
  })
  default = null
}

variable "hostname_configuration" {
  description = "Hostname configuration"
  type = object({
    management = list(object({
      host_name                    = string
      key_vault_id                = string
      certificate                 = string
      certificate_password        = string
      negotiate_client_certificate = bool
    }))
    portal = list(object({
      host_name                    = string
      key_vault_id                = string
      certificate                 = string
      certificate_password        = string
      negotiate_client_certificate = bool
    }))
    developer_portal = list(object({
      host_name                    = string
      key_vault_id                = string
      certificate                 = string
      certificate_password        = string
      negotiate_client_certificate = bool
    }))
    proxy = list(object({
      default_ssl_binding          = bool
      host_name                    = string
      key_vault_id                = string
      certificate                 = string
      certificate_password        = string
      negotiate_client_certificate = bool
    }))
    scm = list(object({
      host_name                    = string
      key_vault_id                = string
      certificate                 = string
      certificate_password        = string
      negotiate_client_certificate = bool
    }))
  })
  default = null
}

variable "apis" {
  description = "Map of APIs to create in API Management"
  type = map(object({
    revision              = string
    display_name          = string
    path                  = string
    protocols             = list(string)
    description           = string
    service_url           = string
    subscription_required = bool
    version               = string
    version_set_id        = string
    import = object({
      content_format = string
      content_value  = string
      wsdl_selector = object({
        service_name  = string
        endpoint_name = string
      })
    })
    oauth2_authorization = object({
      authorization_server_name = string
      scope                     = string
    })
    openid_authentication = object({
      openid_provider_name         = string
      bearer_token_sending_methods = list(string)
    })
    subscription_key_parameter_names = object({
      header = string
      query  = string
    })
  }))
  default = {}
}

variable "products" {
  description = "Map of products to create in API Management"
  type = map(object({
    display_name          = string
    subscription_required = bool
    approval_required     = bool
    published             = bool
    description           = string
    terms                 = string
    subscriptions_limit   = number
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
