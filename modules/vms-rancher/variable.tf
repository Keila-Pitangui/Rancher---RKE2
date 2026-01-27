
variable "nodes_k8s" {

  description = "Map de vm para rancher"
  type = map(object({
    size = string
    image = string
    region= string
    tags = list(string)
  }))

  default = {
    "rancher-server" = {
      size = "s-2vcpu-4gb"
      image = "ubuntu-24-04-x64"
      region = "nyc1"
      tags = ["rancher-server", "control-plane", "worker","etcd"]
    },
    "k8s-02" = {
      size   = "s-2vcpu-4gb"
      image = "ubuntu-24-04-x64"
      region = "nyc1"
      tags   = [ "rancher-server", "k8s-node-02", "control-plane", "worker", "etcd"]
    },
    "k8s-03" = {
      size = "s-2vcpu-4gb"
      image = "ubuntu-24-04-x64"
      region = "nyc1"
      tags   = ["rancher-server", "k8s-node-03", "control-plane", "worker", "etcd"]
    }
}
}