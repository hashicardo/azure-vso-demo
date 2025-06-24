variable "prefix" {
  type        = string
  description = "A friendly prefix for resources"
  default     = "hashicardo"
}

variable "vault_address" {
  type        = string
  description = "The address of the Vault server"
  default     = "https://vault.ricardorompar.com:8200"
}