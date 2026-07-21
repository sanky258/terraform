variable "resource_group_name" {
  description = "Name of the resource group for the VM"
  type        = string
  default     = "rg-learning-vm"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "canadacentral"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "vm-learning01"
}

variable "vm_size" {
  description = "VM SKU size"
  type        = string
  default     = "Standard_B1s" # cheap, good for learning
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Your SSH public key contents (e.g. contents of ~/.ssh/id_rsa.pub)"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}
