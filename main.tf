resource "digitalocean_project" "rancher_rke" {
  name        = "Rancher_RKE2"
  description = "A project to represent development resources."
  purpose     = "Web Application"
  environment = "Development"
}

module "meus_servidores" {
  source = "./modules/vms-rancher"
}