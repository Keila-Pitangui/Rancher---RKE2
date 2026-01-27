variable "do_token" {
  type        = string
  sensitive   = true
  description = "token de conexão digital ocean"
}

variable "image" {
  type        = string
  description = "sistema operacional do droplet"
  default     = "ubuntu-22-04-x64"
}

variable "region" {
  type        = string
  description = "região do droplet"
  default     = "nyc2"
}

variable "nodes_k8s" {

  description = "Map de vm para rancher"
  type = map(object({
    size = string
    tags = list(string)
  }))

  default = {
    "rancher-server" = {
      size = "s-2vcpu-4gb-120gb"
      tags = ["rancher-server", "control-plane", "worker"]
    },
    "k8s-02" = {
      size   = "s-2vcpu-4gb-120gb"
      region = "nyc2"
      tags   = ["k8s-node-02", "control-plane", "worker"]
    },
    "k8s-03" = {
      size = "s-2vcpu-4gb-120gb"
      tags = ["k8s-node-03", "control-plane", "worker"]
    },
    "k8s-04" = {
      size = "s-2vcpu-4gb-120gb"
      tags = ["k8s-node-04", "control-plane", "worker"]
    }
  }

}