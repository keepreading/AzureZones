module "VMs" {
  source                        = "../."
  region                        = "eastus"
  nblinuxvms                    = "3"
  nbwinvms                      = ""
  avzones                       = "true"
  avset                         = "false"
  boot_diagnostics              = "false"
  boot_diagnostics_sa_type      = "Premium_LRS"
  proj_name                     = "skachar1184"
  app_env                       = "dev"
  admin_username                = "skachar"
  admin_password                = "P@$$w0rd1234!"
  delete_os_disk_on_termination = "true"
  data_disk                     = "true"
  data_disk_size_gb             = "64"
  data_sa_type                  = "Premium_LRS"
  tags = {

    Environment  = "dev"
    proj_name    = "Test"
    loadbalancer = "PIP"
    AMPO         = "2345"
    HIR          = "Test For Av. Zones."
  }
}


output "LB_PIP" {
  value = module.VMs.ip_address
}
output "FQDN_Zone1" {
  value = module.VMs.fqdn_zone1
}

output "LB_PIP2" {
  value = module.VMs.ip_address2
}
output "FQDN_Zone2" {
  value = module.VMs.fqdn_zone2
}

output "LB_PIP3" {
  value = module.VMs.ip_address3
}
output "FQDN_Zone3" {
  value = module.VMs.fqdn_zone3
}
