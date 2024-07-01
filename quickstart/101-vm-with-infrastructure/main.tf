resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

output "pet_name" {
  value = random_pet.rg_name.id
}
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${var.resource_name_prefix}-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnets" {
  for_each             = var.subnet_map
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.${each.value.prefix}.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  for_each            = var.subnet_map
  name                = "${each.value.name}-IP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.resource_name_prefix}-NetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  for_each            = var.subnet_map
  name                = each.value.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name      = "${each.value.name}-conf"
    subnet_id = azurerm_subnet.my_terraform_subnets[each.key].id
    #   subnet_id                     = [azurerm_subnet.my_terraform_subnets[each.key].id]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip[each.key].id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg_association1" {
  for_each                  = var.subnet_map
  network_interface_id      = azurerm_network_interface.my_terraform_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}


# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create linux virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm1" {
  name = "${var.resource_name_prefix}${local.trimmed_prefix}VM1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  #  network_interface_ids = ${output.nic_ids{1}}
  network_interface_ids = [azurerm_network_interface.my_terraform_nic["subnet1"].id]
  size                  = "Standard_DS11_v2"

  os_disk {
    name                 = "${var.resource_name_prefix}-OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username = var.username
    public_key = file("~/.ssh/id_rsa.pub")
    #public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

#Create Windows VM
resource "azurerm_windows_virtual_machine" "myterraformvm2" {
  name = "${var.resource_name_prefix}${local.trimmed_prefix}VM2"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_DS11_v2"
  admin_username        = var.username
  admin_password        = var.password
  network_interface_ids = [azurerm_network_interface.my_terraform_nic["subnet2"].id]
  os_disk {
    name                 = "${var.resource_name_prefix}-OsDisk2"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

#Create storage for disaster recovery
resource "azurerm_storage_account" "dr_storage_account" {
  count = var.disaster_recovery_copies
  name                     = "drstorage${count.index}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
















