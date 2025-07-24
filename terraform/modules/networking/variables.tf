# Networking Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnet_address_spaces" {
  description = "Address spaces for subnets"
  type = object({
    app_subnet      = list(string)
    database_subnet = list(string)
    cache_subnet    = list(string)
    gateway_subnet  = list(string)
  })
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection for virtual network"
  type        = bool
  default     = false
}
