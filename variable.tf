variable "location" {
  default = "East Asia" 
}

variable "rg" {
  default = "rg-tf-azure-sample"      
}

variable "env" {
  default = "default"      
}

variable "virtualnet" {
  default = "vnet-tf-azure-sample"
}

variable "vnet-subnet" {
  default = "subnet-aks-tf-azure-sample"
}

variable "aks" {
  default = "aks-tf-azure-sample"
}

variable "aks_dns_prefix" {
  default = "dns-aks-tf-azure-sample"
}

variable "aks_vm_size" {
  default = "Standard_D2_v2"
  
}
# Windows node required
variable "profile_win_name" {
  default = "AzureUser"
}

variable "profile_win_pass" {
  default = "!QAZ2wsx3edcIloveAzure"
}

