output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}


output "subnet_ids" {
  value = { for s in azurerm_subnet.my_terraform_subnets : s.name => s.id }
}

output "nic_ids" {
  value = { for n in azurerm_network_interface.my_terraform_nic : n.name => n.id }
}