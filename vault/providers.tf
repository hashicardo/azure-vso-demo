terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.0.0"
    }
  }
}

provider "vault" {
  address = var.vault_address
  # token passed via VAULT_TOKEN
}
