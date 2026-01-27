output "ips_publicos" {
  value = [for vm in digitalocean_droplet.rancher_vms_doplet : vm.ipv4_address]
  description = "Lista apenas com os IPs para usar no seu arquivo de configuração do RKE2"
}