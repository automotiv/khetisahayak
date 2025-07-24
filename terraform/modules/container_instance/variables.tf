# Container Instance Module Variables

variable "name_prefix" {
  description = "Name prefix for Container Instance resources"
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

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
  default     = "nginx:latest"
}

variable "cpu_cores" {
  description = "CPU cores to allocate"
  type        = number
  default     = 0.5
}

variable "memory_gb" {
  description = "Memory in GB to allocate"
  type        = number
  default     = 1.0
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 80
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "registry_server" {
  description = "Container registry server URL"
  type        = string
  default     = null
}

variable "registry_username" {
  description = "Container registry username"
  type        = string
  default     = null
  sensitive   = true
}

variable "registry_password" {
  description = "Container registry password"
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
