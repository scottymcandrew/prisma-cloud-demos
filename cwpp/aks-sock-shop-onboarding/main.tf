# This script implies Service Principal or interactive AZ Logon before script invocation.
# SP is required if running from CI/CD. If using this method, set ENV as below

## export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
## export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
## export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
## export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_aks" {
  location = "West Europe"
  name = "RG_aks-sock-shop-demo"
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  dns_prefix = "aks-sock-shop-demo"
  location = azurerm_resource_group.rg_aks.location
  name = "aks-sock-shop-demo"
  resource_group_name = azurerm_resource_group.rg_aks.name

  default_node_pool {
    name = "akspool1"
    vm_size = "Standard_D2_v2"
    node_count = 1
  }
  identity {
    type = "SystemAssigned"
  }
  tags = {
    Environment = "Lab"
  }
  # Connect kubectl to local shell
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.rg_aks.name} --name ${azurerm_kubernetes_cluster.aks-cluster.name} --overwrite-existing"
  }

  provisioner "local-exec" {
    command = "kubectl create ns twistlock"
  }
  provisioner "local-exec" {
    command = "kubectl create ns sock-shop"
  }

  provisioner "local-exec" {
    # MacOS
    command = "./pcc_defender_install_mac.sh"
  }

  # Deploy sock-shop
  provisioner "local-exec" {
    command = "kubectl apply -f ./complete-demo.yaml"
  }

}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks-cluster.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks-cluster.kube_config_raw
}


