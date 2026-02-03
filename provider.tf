terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    endpoint                    = "nyc1.digitaloceanspaces.com" # Endereço da DO
    region                      = "us-east-1"                   # Precisa estar aqui, mas é ignorado pela DO
    bucket                      = "rancher-rke2"
    key                         = "projeto/rancher-rke2-terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}