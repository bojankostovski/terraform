variable "resource_group_location" {
  type        = string
  default     = "West Europe" #East US
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}
variable "password" {
  default = "P@$$w0rd1234!"
}
variable "resource_name_prefix" {
  type        = string
  default     = "holx"
  description = "requested variable"
}

variable "disaster_recovery_copies" {
  type = number
  default = 1
  description = "specify how many storage accounts to creates"
}

variable "subnet_map" {
  type = map(object({
    name   = string
    prefix = string
    nic    = string

  }))

  default = {
    "subnet1" = {
      name   = "subnet1"
      prefix = "1"
      nic    = "nic1"
    }
    "subnet2" = {
      name   = "subnet2"
      prefix = "2"
      nic    = "nic2"
    }
  }
}
