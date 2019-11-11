variable "proj_name" {
  type        = "string"
  description = "Project acronym"
}
variable "region" {
  type        = "string"
  default     = "eastus2"
  description = "Region to deploy your resource"
}
variable "tags" {
  type = "map"
}
variable "app_env" {
  description = "App environment e.g. dev, qa, staging, prod"
  default     = "dev"
}
variable "ssh_key" {
  description = "Path to the public key to be used for ssh access to the VM.  Only used with non-Windows vms and can be left as-is even if using Windows vms. If specifying a path to a certification on a Windows machine to provision a linux vm use the / in the path versus backslash. e.g. c:/home/id_rsa.pub"
  default     = "~/.ssh/id_rsa.pub"
}
variable "sku" {
  default = {
    westus = "16.04-LTS"
    eastus = "18.04-LTS"
  }
}
variable "vm_os_simple" {
  default = "UbuntuServer"
}

variable "admin_username" {
  description = "The admin username of the VM that will be deployed"
  default     = "skachar"
}
variable "admin_password" {
  description = "Passowrd for VMs, this shouldn't be used in favor of SSH"
}
variable "avzones" {
  description = "Zones allowed; East US, East US 2, West US 2, Central US, France Central, North Europe, UK South, West Europe, Japan East, Southeast Asia"
  default     = "False"
}
variable "avset" {
  description = "Boolean Variable to enable an Availability Set"
  default     = "false"
}
variable "nblinuxvms" {
  description = "Number of Linux VMs to build."
}
variable "nbwinvms" {
  description = "Number of Windows VMs to build."
}
variable "boot_diagnostics" {
  description = "Should there be a storage account for the boot diags?"
  default     = "false"
}
variable "boot_diagnostics_sa_type" {
  description = "(Optional) Storage account type for boot diagnostics"
  default     = "Standard_LRS"
}
variable "data_disk" {
  description = "should there be a data disk"
  default     = "false"
}

variable "data_disk_size_gb" {
  description = "Defines the size of the datadisk being attached in gb"
  default     = "32"
}

variable "data_sa_type" {
  description = "Defines the type of datadisk used with the vm/vms"
  type        = "string"
  default     = "Premium_LRS"
}
variable "delete_os_disk_on_termination" {
  description = "Delete disk on cleanup"
  default     = "true"
}
variable "nicid" {
  type = "list"
  default = [
    {
    "0" = "azurerm_network_interface.nic1.id"
    },
    {
    "1" = "azurerm_network_interface.nic2.id"
    },
    {
    "2" = "azurerm_network_interface.nic3.id"
    }
  ]
}
variable "aaz" {
  type = "list"
  default = ["1","2","3"]
}





