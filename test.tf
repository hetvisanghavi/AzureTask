# Configure the Microsoft Azure Provider
provider "azurerm" {

}
variable "PATH_TO_PUBLIC_KEY" {
default = "id_rsa.pub"}
variable "PATH_TO_PRIVATE_KEY" {
  default = "./id_rsa"
}
# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    
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

    tags = {
        environment = "Terraform Demo"
    }
}
resource "azurerm_network_security_rule" "allohttp" {
    network_security_group_name = "myNetworkSecurityGroup"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    

        name                       = "Allow HTTP"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    

}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "ajhbj"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
 ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd2E+ZRW1oIwhJ1IXwhEdZb+1Sd7KsTVzkMcnwPI7C9ceTgX72MwCE7VGiBa/IBYNnni8Tn1OpMqS9mBarhnYfg0HX6HdMheP2r9Seh6R0ToK67Ss3E2b/R383mXQlQAhC+bzRMHhhHkWYcVLUhIo+vnEGy72aBrvaoWf9n1n2XuV9KUMBIUPJW1b4+QPZFgf2gJdsaR3vFZ78LfzeT7ZITsHauD8zyASk45IBYKm28g6mph4dewX03v5RTru/wgKMnvDKZBcNJssCHmjzC0MOpps5p3KQDhTFPwThNnHZm/1gIf6ShfCPhHz53DcNquCk2v7A5Ky3xAG0PB2iO5nb hetvi@hetvi"
        }       
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo"
    }

}

resource "null_resource""test"
{

provisioner "file" 
{
		connection 
		{
			type = "ssh"
			user = "azureuser"
			host = "40.121.197.131"
			#host = "${azurerm_public_ip.myterraformpublicip.id}"
    			private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"			
			
		}
	source = "script.sh"
	destination = "/home/azureuser/script.sh"
		
}
 provisioner "remote-exec" {
connection 
		{
			type = "ssh"
			user = "azureuser"
			host = "40.121.197.131"
			#host = "${azurerm_public_ip.myterraformpublicip.id}"
    			private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"			
			
		}
    inline = [
      "chmod +x /home/azureuser/script.sh",
      "sudo /home/azureuser/script.sh"
    ]
}}
