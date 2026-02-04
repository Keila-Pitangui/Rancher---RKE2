variable "region" {
  type = string
  description = "environment region"
  default = "nyc1"
}

variable "name_project" {
  type = string
  description = "project name"
  default = "Rancher-RKE"
}


variable "nodes_k8s" {

  description = "Map de vm para rancher"
  type = map(object({
    size = string
    image = string
    region= string
    tags = list(string)
  }))

  default = {
    "k8s-02" = {
      size   = "s-2vcpu-4gb"
      image = "ubuntu-24-04-x64"
      region = "nyc1"
      tags   = ["k8s-node-02", "control-plane", "worker", "etcd"]
    },
    "k8s-03" = {
      size = "s-2vcpu-4gb"
      image = "ubuntu-24-04-x64"
      region = "nyc1"
      tags   = ["k8s-node-03", "control-plane", "worker", "etcd"]
    }
    "rancher-server" = {
      size = "s-2vcpu-4gb"
      image = "ubuntu-24-04-x64"
      region = "nyc1"
      tags = ["rancher-server", "control-plane", "worker","etcd"]
    }
}
}

variable "port_firewall_dynamic" {
  description = "firewall ports"
  type = list(number)
  default = [80, 443, 22, 6443, 9345]
}

variable "lb_dynamic" {
  description = "firewall ports"
  type = list(number)
  default = [80, 443, 22, 6443, 9345]
}