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

resource "digitalocean_firewall" "rancher_firewall" {
  name = "rancher-cluster-firewall"
  
  # Aplica a todos os Droplets do cluster
  droplet_ids = [for vm in digitalocean_droplet.rancher_vms_doplet : vm.id]

  # 1. Acesso Externo (UI e API)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80" # Necessário para o redirecionamento HTTP -> HTTPS
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "6443" # Kubernetes API
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22" 
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Comunicação INTERNA (Entre os nós do cluster)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_tags      = ["control-plane", "worker"] 
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_tags      = ["control-plane", "worker"]
  }

  # Regras de Saída (Outbound) - Permitir tudo
  outbound_rule {
    protocol                = "tcp"
    port_range              = "1-65535"
    destination_addresses   = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol                = "udp"
    port_range              = "1-65535"
    destination_addresses   = ["0.0.0.0/0", "::/0"]
  }
}