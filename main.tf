provider "azurerm" {
  #Use azure provider 1.35 at least, no beta providers
  version = "~>1.35.0"
}
resource "random_id" "vm-sa" {
  byte_length = 6
}
resource "azurerm_resource_group" "rg" {
  name     = "${var.proj_name}-rg-${var.region}-${var.app_env}"
  location = var.region
  tags     = var.tags
}
resource "azurerm_public_ip" "pip" {
  name                = "${var.proj_name}-lbpip-${var.region}-${var.app_env}"
  location            = var.region
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"   #Public IP Standard SKUs require allocation_method to be set to Static
  sku                 = "Standard" #Standard SKU Required for Zones
  domain_name_label   = lower("${var.proj_name}-PIP-Zone1")
  zones               = ["1"]
}
resource "azurerm_public_ip" "pip2" {
  name                = "${var.proj_name}-lbpip2-${var.region}-${var.app_env}"
  location            = var.region
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"   #Public IP Standard SKUs require allocation_method to be set to Static
  sku                 = "Standard" #Standard SKU Required for Zones
  domain_name_label   = lower("${var.proj_name}-PIP-Zone2")
  zones               = ["2"]
}
resource "azurerm_public_ip" "pip3" {
  name                = "${var.proj_name}-lbpip3-${var.region}-${var.app_env}"
  location            = var.region
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"   #Public IP Standard SKUs require allocation_method to be set to Static
  sku                 = "Standard" #Standard SKU Required for Zones
  domain_name_label   = lower("${var.proj_name}-PIP-Zone3")
  zones               = ["3"]
}
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.proj_name}-vnet-${var.region}-${var.app_env}"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.proj_name}-subnet1-${var.region}-${var.app_env}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.2.0/24"
}
resource "azurerm_network_security_group" "nsg" {
  name                = "Nsg-Subnet1"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "FordStdProxies"
    priority                   = "1200"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443", "3389"]
    source_address_prefixes    = ["136.1.0.0/16", "136.2.0.0/16", "136.8.0.0/16"]
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_rule" "app_rules" {
  name                        = "NsgRule"
  priority                    = "1210"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "136.1.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
  depends_on = [
    azurerm_network_security_group.nsg
  ]
}
# Associate each NSG with the corresponding subnet
resource "azurerm_subnet_network_security_group_association" "binding" {
  subnet_id                 = "${azurerm_subnet.subnet1.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}
#load balancer section
resource "azurerm_lb" "lb" {
  name                = "externallb"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "standard" #standard SKU needed to support zones

  frontend_ip_configuration {
    name                 = "primary1"
    public_ip_address_id = "${azurerm_public_ip.pip.id}"
  }
  frontend_ip_configuration {
    name                 = "primary2"
    public_ip_address_id = "${azurerm_public_ip.pip2.id}"
  }
  frontend_ip_configuration {
    name                 = "primary3"
    public_ip_address_id = "${azurerm_public_ip.pip3.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "lbbap" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "acctestpool"
}
resource "azurerm_lb_probe" "ssh" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "ssh-running-probe"
  port                = "22"
}

resource "azurerm_lb_rule" "lbrule" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.lbbap.id}"
  frontend_ip_configuration_name = "primary1"
  probe_id                       = "${azurerm_lb_probe.ssh.id}"
}
resource "azurerm_lb_nat_rule" "lbnr1" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "SSHHost1"
  protocol                       = "Tcp"
  frontend_port                  = 2201
  backend_port                   = 22
  frontend_ip_configuration_name = "primary1"
}
resource "azurerm_lb_nat_rule" "lbnr2" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "SSHHost2"
  protocol                       = "Tcp"
  frontend_port                  = 2202
  backend_port                   = 22
  frontend_ip_configuration_name = "primary2"
}
resource "azurerm_lb_nat_rule" "lbnr3" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "SSHHost3"
  protocol                       = "Tcp"
  frontend_port                  = 2203
  backend_port                   = 22
  frontend_ip_configuration_name = "primary3"
}
##########  End Load Balancer Section ##############
resource "azurerm_network_interface" "nic" {
  count               = "${var.nblinuxvms}"
  name                = "nic${count.index}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                                = "nicipconfig"
    subnet_id                           = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation       = "Static"
    private_ip_address                  = "10.0.2.${count.index + 5}"
    load_balancer_inbound_nat_rules_ids = ["${element(azurerm_lb_nat_rule.*.id, count.index)}"]
    #load_balancer_inbound_nat_rules_ids = ["${azurerm_lb_nat_rule.lbnr1.id}"]
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nibapa" {
  network_interface_id    = "${azurerm_network_interface.nic1.id}"
  ip_configuration_name   = "nicipconfig"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.lbbap.id}"
}

resource "azurerm_network_interface_nat_rule_association" "test" {
  network_interface_id  = "${azurerm_network_interface.nic1.id}"
  ip_configuration_name = "nicipconfig"
  nat_rule_id           = "${azurerm_lb_nat_rule.lbnr1.id}"
}

# resource "azurerm_network_interface" "nic2" {
#   name                = "nic2"
#   location            = "${azurerm_resource_group.rg.location}"
#   resource_group_name = "${azurerm_resource_group.rg.name}"

#   ip_configuration {
#     name                                = "nicipconfig"
#     subnet_id                           = "${azurerm_subnet.subnet1.id}"
#     private_ip_address_allocation       = "Static"
#     private_ip_address                  = "10.0.2.6"
#     load_balancer_inbound_nat_rules_ids = ["${azurerm_lb_nat_rule.lbnr2.id}"]
#   }
# }

# resource "azurerm_network_interface_backend_address_pool_association" "nibapa2" {
#   network_interface_id    = "${azurerm_network_interface.nic2.id}"
#   ip_configuration_name   = "nicipconfig"
#   backend_address_pool_id = "${azurerm_lb_backend_address_pool.lbbap.id}"
# }

# resource "azurerm_network_interface_nat_rule_association" "test2" {
#   network_interface_id  = "${azurerm_network_interface.nic2.id}"
#   ip_configuration_name = "nicipconfig"
#   nat_rule_id           = "${azurerm_lb_nat_rule.lbnr2.id}"
# }

# resource "azurerm_network_interface" "nic3" {
#   name                = "nic3"
#   location            = "${azurerm_resource_group.rg.location}"
#   resource_group_name = "${azurerm_resource_group.rg.name}"

#   ip_configuration {
#     name                                = "nicipconfig"
#     subnet_id                           = "${azurerm_subnet.subnet1.id}"
#     private_ip_address_allocation       = "Static"
#     private_ip_address                  = "10.0.2.7"
#     load_balancer_inbound_nat_rules_ids = ["${azurerm_lb_nat_rule.lbnr3.id}"]
#   }
# }

# resource "azurerm_network_interface_backend_address_pool_association" "nibapa3" {
#   network_interface_id    = "${azurerm_network_interface.nic3.id}"
#   ip_configuration_name   = "nicipconfig"
#   backend_address_pool_id = "${azurerm_lb_backend_address_pool.lbbap.id}"
# }

# resource "azurerm_network_interface_nat_rule_association" "test3" {
#   network_interface_id  = "${azurerm_network_interface.nic3.id}"
#   ip_configuration_name = "nicipconfig"
#   nat_rule_id           = "${azurerm_lb_nat_rule.lbnr3.id}"
}
###########################################
###########################################
#                                         #
#                                         #
#   VM resources from here down           #
#                                         #
#                                         #
#                                         #
#   VM resources from here down           #
#                                         #
#                                         #
###########################################
###########################################

# resource "azurerm_storage_account" "vm-sa" {
#   count                    = "${var.boot_diagnostics == "true" ? 1 : 0}"
#   name                     = "bootdiag${lower(random_id.vm-sa.hex)}"
#   resource_group_name      = "${azurerm_resource_group.rg.name}"
#   location                 = "${azurerm_resource_group.rg.location}"
#   account_tier             = "${element(split("_", var.boot_diagnostics_sa_type), 0)}"
#   account_replication_type = "${element(split("_", var.boot_diagnostics_sa_type), 1)}"
#   tags                     = "${var.tags}"
# }
# resource "azurerm_availability_set" "as" {
#   count                        = "${var.avset ? 1 : 0}"
#   name                         = "AvailabilitySet"
#   location                     = "${azurerm_resource_group.rg.location}"
#   resource_group_name          = "${azurerm_resource_group.rg.name}"
#   platform_update_domain_count = 5 #defaults to 5
#   platform_fault_domain_count  = 3 #defaults to 3
#   managed                      = "true"
#   tags                         = "${var.tags}"
# }
resource "azurerm_virtual_machine" "vm" {
  count               = "${var.nblinuxvms}"
  name                = "${var.proj_name}${var.app_env}vm${count.index}"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_interface_ids = "${azurerm_network_interface}"
  #network_interface_ids = split(",","${element(["/subscriptions/f77ff0fd-11af-4a46-b3ee-9f92c52bcbdb/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/networkInterfaces/nic1","/subscriptions/f77ff0fd-11af-4a46-b3ee-9f92c52bcbdb/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/networkInterfaces/nic2","/subscriptions/f77ff0fd-11af-4a46-b3ee-9f92c52bcbdb/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/networkInterfaces/nic3"], "${count.index}")}")
  # network_interface_ids = split(",","${element(["azurerm_network_interface.nic1.id","azurerm_network_interface.nic2.id","azurerm_network_interface.nic3.id"], "${count.index}")}")
  vm_size = "Standard_D2S_v3"
  #availability_set_id           = azurerm_availability_set.as[0].id
  tags                          = "${var.tags}"
  zones                         = "${var.avzones}" ? split("","${element(["1","2","3"], "${count.index}")}") : null
  delete_os_disk_on_termination = "${var.delete_os_disk_on_termination}"
  storage_os_disk {
    name              = "${var.proj_name}OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "${lookup(var.sku, var.region)}"
    version   = "latest"
  }
  storage_data_disk {
    name              = "datadisk-${var.proj_name}-${count.index}"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.data_sa_type}"
  }

  os_profile {
    computer_name  = "${var.proj_name}vm${var.app_env}"
    admin_username = "skachar"
    admin_password = "Cr3@t3@Passw0rd@D3pl0ym3ntT!m3"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_key}")}"
    }
  }
#   boot_diagnostics {
#     enabled     = "${var.boot_diagnostics}"
#     storage_uri = "${var.boot_diagnostics == "true" ? join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint) : ""}"
#   }
}
