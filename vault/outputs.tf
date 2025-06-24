output "vault_k8s_auth_role" {
  value = vault_kubernetes_auth_backend_role.simple_app_role.role_name
}