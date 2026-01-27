terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_project" "rancher_rke" {
  name        = "Rancher_RKE2"
  description = "A project to represent development resources."
  purpose     = "Web Application"
  environment = "Development"
}

resource "digitalocean_droplet" "rancher_vms_doplet" {
  for_each = var.nodes_k8s

  name   = each.key        
  size   = each.value.size
  image  = each.value.image
  region = each.value.region
  tags   = each.value.tags
  ssh_keys = [digitalocean_ssh_key.acesso_vms.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update && apt-get install -y curl cloud-utils
    mkdir -p /root/.ssh
    echo "${tls_private_key.chave_vms.private_key_pem}" > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
    ufw disable
  EOF
}

resource "tls_private_key" "chave_vms" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "digitalocean_ssh_key" "acesso_vms" {
  name       = "chave-rancher"
  public_key = tls_private_key.chave_vms.public_key_openssh
}

resource "local_file" "chave_privada_local" {
  content  = tls_private_key.chave_vms.private_key_pem
  filename = "${path.module}/id_rsa_rancher.pem"
  file_permission = "0600"
}