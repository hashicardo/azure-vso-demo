data "vault_kv_secret_v2" "secrets" {
  mount = "secrets"
  name  = "k8s-demo"
}
