terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.80.0"
    }
  }
  /* Store tf file in azure storage */
  backend "azurerm" {
  }
}

/* Configure the Microsoft Azure Provider */
provider "azurerm" {
    # use_msi = true
    features {
    }
    # subscription_id = "00000000-0000-0000-0000-000000000000"
    # tenant_id       = "11111111-1111-1111-1111-111111111111"
    # client_id       = "22222222-2222-2222-2222-222222222222"
    # client_secret   = "aaaaaaaaaaaaaaaaa" 
}

/* Resource Group */
resource "azurerm_resource_group" "resourcegroup" {
  name     = var.rg
  location = var.location
  tags = {
    Environment = var.env
  }
}

/* Create VNet */
resource "azurerm_virtual_network" "virtualnetwork" {
  name                = var.virtualnet
  location            = var.location
  resource_group_name = var.rg
  address_space       = ["10.0.0.0/21"]
  depends_on      = [ azurerm_resource_group.resourcegroup ]
}

resource "azurerm_subnet" "aks-subnet" {
  name           = var.vnet-subnet
  virtual_network_name = azurerm_virtual_network.virtualnetwork.name
  resource_group_name = var.rg
  address_prefixes = ["10.0.1.0/24"]
  depends_on      = [ azurerm_resource_group.resourcegroup ]
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks-subnet.id
}

/* Create AKS
   Ebable AAD IAM & K8S Role
   Change to Fsv2 */ 
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks
  location            = var.location
  resource_group_name = var.rg
  dns_prefix          = var.aks_dns_prefix
  # automatic_channel_upgrade = "none"
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.aks-subnet.id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr = "10.0.4.0/24"
    dns_service_ip = "10.0.4.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  identity {
    type = "SystemAssigned"
  }
  
  # windows_profile {
  #   admin_username = var.profile_win_name
  #   admin_password = var.profile_win_pass
  # }
  # depends_on      = [ azurerm_resource_group.resourcegroup ]
}

# provider "kubernetes"{
#   host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
#   username               = azurerm_kubernetes_cluster.aks.kube_config.0.username
#   password               = azurerm_kubernetes_cluster.aks.kube_config.0.password
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
# }

# resource "kubernetes_namespace" "ns-dev" {
#   metadata {
#     name = "ns-dev"
#   }
#   depends_on = [azurerm_kubernetes_cluster.aks]
# }


/* Create Linux node pool */
resource "azurerm_kubernetes_cluster_node_pool" "linux-node-pool" {
  name                  = "devlinux"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2S_v4" 
  availability_zones    = []
  vnet_subnet_id        = azurerm_subnet.aks-subnet.id
  os_type               = "Linux"
  node_count            = 1
  max_pods              = 100
  os_disk_size_gb       = 128
  enable_auto_scaling   = true
  enable_host_encryption= false
  enable_node_public_ip = false
  fips_enabled          = false
  node_taints           = []
  max_count = 5
  min_count = 1
}

/* storage account */
# resource "azurerm_storage_account" "storage" {
#   name                     = var.storage
#   resource_group_name      = var.rg
#   location                 = var.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   depends_on = [ azurerm_resource_group.resourcegroup ]
# }