# Vault Enterprise VSO demo (Azure)

This repo contains some resources to recreate a demo similar to the VSO demo in the DDR platform. It uses the same app developed by [Rodo](https://github.com/shoootyou).

The resources defined in [aks-vault](./aks-vault/) were taken from the [HashiCorp Education repo](https://github.com/hashicorp-education/learn-terraform-provision-aks-cluster) to deploy an AKS cluster using Terraform.

# Prerequisites
- **Vault**: You'll need a publicly accessible Vault cluster. If you need an enterprise cluster check out [this repo](https://github.com/hashicardo/vault-enterprise-demo) which helps you deploy a simpler version of Vault Enterprise without all the extra requirements for deploying the HVD module.
- **`vault`**: the Vault CLI
- **`az`**: the Azure CLI installed locally
- **`kubectl`**: the K8s CLI.
- **`terraform`**: to deploy all resources outside of K8s.
- **`helm`**

## 1. Deploy AKS cluster
Copy this repo:
```bash
git clone https://github.com/hashicardo/azure-vso-demo.git vso-demo
```

Deploy the AKS cluster. This will also create a resource group in which your AKS cluster will be.
```bash
cd vso-demo/aks-vault
terraform init
terraform apply
# Review the plan and confirm
```

### Configure `kubectl` for your AKS cluster:
Run:
```bash
# Make sure to be in the same directory where you ran terraform (i.e. aks-vault)
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
```

You'll get an output similar to `Merged "beloved-monster-aks" as current context in /Users/USERNAME/.kube/config`

Test:
```bash
kubectl get nodes
```
Example output:
```nocopy
NAME                              STATUS   ROLES    AGE   VERSION
aks-default-87645321-vmss000000   Ready    <none>   25m   v1.32.4
aks-default-87645321-vmss000001   Ready    <none>   25m   v1.32.4
```

## 2. Create kube-tools
A namespace, service account, token and role binding for the token with [kube-tools](./k8s/kube-tools.yaml)
```bash
kubectl apply -f k8s/kube-tools.yaml
```
## 3. Create secrets in your Vault. 
I created a mount called `secrets` with a single secret called `k8s-demo` with the following KV pairs:
- `k8s-ca-base64`: obtained from the `terraform apply` in step 1.
- `k8s-host`: obtained from the `terraform apply` in step 1.
- `k8s-vault-token`: obtained from step 2 running `kubectl describe secrets vault-auth -n simple-app`
## 4. Change [config-vault.tf](./vault/config-vault.tf) according to the outputs of steps 1, 2 and 3.
## 5. Apply configs in Vault:
```bash
cd vault
terraform init
terraform apply
```
## 6. Install the VSO. 
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  --namespace simple-app \
  --create-namespace \
  -f k8s/kube-vso.yaml
```
## 7. Define the app 
Apply the deployment and the service (ClusterIP for this example):
```bash
kubectl apply -f k8s/static-app.yaml
```
## 8. Access the app.
The deployment defined in `static-app.yaml` exposes the app through a public IP with a LoadBalancer type of service. You can get the EXTERNAL-IP of this service by running:
```bash
kubectl get svc -n simple-app
``` 

---
## Debugging:
If you need to change the configs of the VSO deployed with Helm use the `upgrade` command:
```bash
helm upgrade vault-secrets-operator hashicorp/vault-secrets-operator \
  --namespace simple-app \
  -f k8s/kube-vso.yaml
```