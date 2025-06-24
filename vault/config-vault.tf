# NAMESPACE
resource "vault_namespace" "namespace" {
  path = "${var.prefix}-k8s-ns"
}

# SECRETS MOUNT
resource "vault_mount" "credentials" {
  namespace   = vault_namespace.namespace.path
  path        = "creds"
  type        = "kv"
  description = "KV v2 mount for credentials"
  options = {
    version = "2"
  }
}

# SECRETS
resource "vault_generic_secret" "credentials" {
  namespace = vault_namespace.namespace.path
  path      = "${vault_mount.credentials.path}/app/demo-secret"
  data_json = jsonencode({
    message   = "Try VSO by changing this text from Vault!"
    image_url = "/resources/logo.png"
  })
}

# POLICIES
resource "vault_policy" "apps_policy" {
  namespace = vault_namespace.namespace.path
  name      = "apps-policy"

  policy = <<EOT
path "${vault_mount.credentials.path}/*" {
  capabilities = ["create", "read", "update", "patch", "list"]
}
EOT
}

# K8S STUFF
resource "vault_auth_backend" "kube_auth" {
  namespace = vault_namespace.namespace.path
  type      = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kube_auth_cfg" {
  namespace          = vault_namespace.namespace.path
  backend            = vault_auth_backend.kube_auth.path
  kubernetes_ca_cert = base64decode(data.vault_kv_secret_v2.secrets.data["k8s-ca-base64"])
  kubernetes_host    = data.vault_kv_secret_v2.secrets.data["k8s-host"]
  token_reviewer_jwt = data.vault_kv_secret_v2.secrets.data["k8s-vault-token"]
}

resource "vault_kubernetes_auth_backend_role" "simple_app_role" {
  namespace                        = vault_namespace.namespace.path
  backend                          = vault_auth_backend.kube_auth.path
  role_name                        = "simple-app"
  bound_service_account_names      = ["vault-auth"]   #From K8s
  bound_service_account_namespaces = ["simple-app"]   #From K8s
  token_max_ttl                    = 86400
  token_policies                   = [vault_policy.apps_policy.name]
  audience                         = "vault"
}