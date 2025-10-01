variable "vm_name" { # TODO: Update calling stacks to pass an explicit VM name.
  description = "Name of the Linux virtual machine."
  type        = string
}

variable "resource_group_name" { # TODO: Provide the resource group name from the parent stack.
  description = "Resource group that will host the virtual machine resources."
  type        = string
}

variable "location" { # TODO: Set the Azure region via the parent configuration.
  description = "Azure region for the VM and related resources."
  type        = string
}

variable "subnet_id" { # TODO: Supply the subnet ID that matches your lab network.
  description = "Subnet ID where the network interface will be attached."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
  default     = "azureuser" # TODO: Override this default if your lab standards require a different admin name.
}

variable "admin_password" {
  description = "Optional admin password for the VM. Provide either this or an SSH public key."
  type        = string
  default     = null # TODO: Provide a secure password via the parent module when using password auth.
  sensitive   = true

  validation {
    condition     = var.admin_password == null || length(var.admin_password) >= 12
    error_message = "Admin password must be at least 12 characters or be omitted when using SSH."
  }
}

variable "admin_ssh_public_key" {
  description = "Optional SSH public key for the admin user. Provide either this or an admin password."
  type        = string
  default     = null # TODO: Pass your OpenSSH public key when relying on key-based authentication.

  validation {
    condition     = var.admin_password != null || (var.admin_ssh_public_key != null && length(trimspace(var.admin_ssh_public_key)) > 0)
    error_message = "Provide either admin_password or admin_ssh_public_key."
  }

  validation {
    condition     = var.admin_ssh_public_key == null || can(regex("^ssh-", var.admin_ssh_public_key))
    error_message = "SSH public key must be in the standard OpenSSH format."
  }
}

locals {
  use_password_auth = var.admin_password != null
}

resource "azurerm_network_interface" "nic" { # TODO: Confirm NIC naming and subnet wiring match your lab topology.
  name                = "${var.vm_name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

resource "azurerm_public_ip" "ip" {
  name                = "${var.vm_name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username

  disable_password_authentication = !local.use_password_auth
  network_interface_ids           = [azurerm_network_interface.nic.id]

  dynamic "admin_ssh_key" {
    for_each = local.use_password_auth ? [] : [1]

    content {
      username   = var.admin_username
      public_key = var.admin_ssh_public_key
    }
  }

  admin_password = local.use_password_auth ? var.admin_password : null # TODO: Ensure either admin_password or admin_ssh_public_key is set upstream.
}

output "vm_id" { # TODO: Consume this output in the parent module to expose VM identity.
  description = "ID of the created virtual machine."
  value       = azurerm_linux_virtual_machine.vm.id
}

output "public_ip" { # TODO: Surface this value upstream if you need to publish the VM endpoint.
  description = "Public IP address assigned to the virtual machine."
  value       = azurerm_public_ip.ip.ip_address
}
