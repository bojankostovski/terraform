
# Create the Resource Group

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create three virtual networks

resource "random_pet" "virtual_network_name" {
  prefix = "vnet"
}
resource "azurerm_virtual_network" "vnet" {
  count = 3

  name                = "${random_pet.virtual_network_name.id}-0${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.${count.index}.0.0/16"]
}

# Add a subnet to each virtual network

resource "azurerm_subnet" "subnet_vnet" {
  count = 3

  name                 = "default"
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.${count.index}.0.0/24"]
}

# Create a Virtual Network Manager instance

data "azurerm_subscription" "current" {
}

resource "azurerm_network_manager" "network_manager_instance" {
  name                = "network-manager"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  scope_accesses      = ["Connectivity"]
  description         = "example network manager"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

# Create a network group

resource "azurerm_network_manager_network_group" "network_group" {
  name               = "network-group"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}

# Add the three virtual networks to the network group as static members

resource "azurerm_network_manager_static_member" "static_members" {
  count = 3

  name                      = "static-member-0${count.index}"
  network_group_id          = azurerm_network_manager_network_group.network_group.id
  target_virtual_network_id = azurerm_virtual_network.vnet[count.index].id
}

# Create a connectivity configuration

resource "azurerm_network_manager_connectivity_configuration" "connectivity_config" {
  name                  = "connectivity-config"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "Mesh"
  applies_to_group {
    group_connectivity = "None"
    network_group_id   = azurerm_network_manager_network_group.network_group.id
  }
}


# Commit deployment

resource "azurerm_network_manager_deployment" "commit_deployment" {
  network_manager_id = azurerm_network_manager.network_manager_instance.id
  location           = azurerm_resource_group.rg.location
  scope_access       = "Connectivity"
  configuration_ids  = [azurerm_network_manager_connectivity_configuration.connectivity_config.id]
}