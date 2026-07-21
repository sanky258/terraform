output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_id" {
  description = "Resource ID of the VM"
  value       = azurerm_linux_virtual_machine.main.id
}

output "ssh_connection_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}
