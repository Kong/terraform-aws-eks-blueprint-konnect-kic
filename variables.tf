variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
}

variable "kong_config" {
  description = "Kong addon configuration values"
  type        = any
  default     = {}
}

variable "create_delay_duration" {
  description = "The duration to wait before creating resources"
  type        = string
  default     = "30s"
}

variable "create_delay_dependencies" {
  description = "Dependency attribute which must be resolved before starting the `create_delay_duration`"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
