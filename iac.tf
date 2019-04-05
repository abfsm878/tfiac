resource "azurerm_resource_group" "test2" {
    name = "Terraform-IaC"
    location ="Canada Central"
    tags = {environment = "TF IaC"}
}

resource "azurerm_storage_account" "testsa" { 
    name                     = "teststaaccountfortf"
    resource_group_name      = "${azurerm_resource_group.test2.name}"
    location                 = "Canada Central" 
    account_tier             = "standard" 
    account_replication_type = "LRS"
}
resource "azurerm_virtual_network" "test" {

name                = "terraform-vNET"
address_space       = ["10.0.0.0/16"]
location            = "${azurerm_resource_group.test2.location}"
resource_group_name = "${azurerm_resource_group.test2.name}"
}
resource "azurerm_subnet" "test" {
    name                 = "FrontEnd-Subnet"
    resource_group_name  = "${azurerm_resource_group.test2.name}"
    virtual_network_name = "${azurerm_virtual_network.test.name}"
    address_prefix       = "10.1.0.0/24" 
}
resource "azurerm_network_interface" "test" {
    name                 = "TerraformNIC"
    location             = "${azurerm_resource_group.test2.location}"
    resource_group_name  = "${azurerm_resource_group.test2.name}"

    ip_configuration {
        name                            = "NIC1Configurations"
        subnet_id                       = "${azurerm_subnet.test.subnet_id}"
        private_ip_address_allocation   = "dynamic" 
    }
}
resource "azurerm_managed_disk" "test" {
    name                                = "datadisk1"
    location                            = "${azurerm_resource_group.test2.location}"
    resource_group_name                 = "${azurerm_resource_group.test2.name}"
    storage_account_type                = "Standard_LRS"
    create_option                       = "Empty"
    disk_size_gb                        = "60"
}
resource "azurerm_virtual_machine" "test" {
name                            = "test${count.index}"
location                        = "${azurerm_resource_group.test2.location}"
resource_group_name             = "${azurerm_resource_group.test2.name}"
network_interface_ids           = "${azurerm_network_interface.test.network_interface_ids}"
vm_size                         = "Standard_DS1_v2"
count                           = 2 
}
storage_image_reference {
publisher                       = "MicrosoftWindowsServer"
offer                           = "WindowsServer"
sku                             = "2016-Datacenter"
version                         = "latest"
}

storage_os_disk {
name                            = "myosdisk"
caching                         = "ReadWrite"
create_option                   = "FromImage"
managed_disk_type               = "Standard_LRS"
}

storage_data_disk {
name                            = "${azurerm_managed_disk.test.name}"
managed_disk_id                 = "${azurerm_managed_disk.test.managed_disk_id}"
create_option                   = "Attach"
lun                             = 1
disk_size_gb                    = "${azurerm_managed_disk.test.disk_size_gb}"
}

os_profile {
computer_name                   = "VM1"
admin_username                  = "vmadmin"
admin_password                  = "Password1"
}

os_profile_windows_config {

}
