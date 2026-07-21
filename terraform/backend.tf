terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Remote state — this is the "large org" pattern: state lives in Azure
  # Storage, not on anyone's laptop, and Azure handles locking for you.
  #
  # You must create this storage account + container ONE TIME manually
  # (see README "One-time bootstrap" section) before `terraform init` works.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate19714" # must be globally unique
    container_name       = "tfstate"
    key                  = "vm.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
