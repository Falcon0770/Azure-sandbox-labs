resource "azurerm_resource_group" "lab" {
  name     = "rg-linuxlab-${var.user_id}"
  location = var.location
}

module "linux_vm" {
  source              = "../../modules/linux_vm"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.location
  vm_name             = "linuxlab-${var.user_id}"
  subnet_id           = var.subnet_id
}
