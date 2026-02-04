terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_project" "rancher_project" {
  name = var.name_project
  lifecycle { prevent_destroy = true } #impedir o destroy desse recurso
  description = "A project to represent development resources."
  purpose     = "Web Application"
  environment = "Development"
  resources   = [for vm in digitalocean_droplet.rancher_vms : vm.urn]
}

resource "digitalocean_droplet" "rancher_vms" {
  for_each = var.nodes_k8s

  name     = each.key
  size     = each.value.size
  image    = each.value.image
  region   = each.value.region
  tags     = each.value.tags
  ssh_keys = [digitalocean_ssh_key.acesso_vms.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update && apt-get install -y curl cloud-u_doplettils
    mkdir -p /root/.ssh
    echo "${tls_private_key.chave_vms.private_key_pem}" > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
    ufw disable
    mkdir -p /etc/rancher/rke2/
    cd /etc/rancher/rke2/
    touch config.yaml
    chmod -R 777 config.yaml
    cat >'config.yaml' <<EOT
    token: rancher-secret
    server: rancher.keilapitangui.com.br:9345
    tls-san:
      - rancher.keilapitangui.com.br
      - cluster.keilapitangui.com.br
    EOT
    curl -sfL https://get.rke2.io | sh -
    systemctl enable rke2-server.service
    systemctl start rke2-server.service
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
  content         = tls_private_key.chave_vms.private_key_pem
  filename        = "${path.module}/id_rsa_rancher.pem"
  file_permission = "0600"
}

resource "digitalocean_firewall" "rancher_firewall" {
  name = "rancher-cluster-firewall"

  # Aplica a todos os Droplets do cluster
  droplet_ids = [for vm in digitalocean_droplet.rancher_vms : vm.id]

  dynamic "inbound_rule" {
    for_each = var.port_firewall_dynamic

    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  # Comunicação INTERNA (Entre os nós do cluster)
  inbound_rule {
    protocol    = "tcp"
    port_range  = "1-65535"
    source_tags = ["control-plane", "worker"]
  }

  inbound_rule {
    protocol    = "udp"
    port_range  = "1-65535"
    source_tags = ["control-plane", "worker"]
  }

  # Regras de Saída (Outbound) - Permitir tudo
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  dynamic "outbound_rule" {

    for_each = var.outboud_firewall

    content {
      protocol              = []
      port_range            = outbound_rule.value
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }

  }
}


resource "digitalocean_loadbalancer" "lb_public" {

  droplet_ids = [for vm in digitalocean_droplet.rancher_vms : vm.id]

  name   = "lb-rancher-server"
  region = var.region

  dynamic "forwarding_rule" {

    for_each = var.lb_dynamic
    content {
      entry_protocol  = "tcp"
      entry_port      = forwarding_rule.value
      target_protocol = "tcp"
      target_port     = forwarding_rule.value
    }
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }
}