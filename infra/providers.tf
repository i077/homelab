terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.8.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.19.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
  }

  backend "s3" {
    bucket    = "imranh-iac"
    endpoints = { s3 = "s3.us-east-005.backblazeb2.com" }
    region    = "us-east-005"
    key       = "homelab.tfstate"

    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}

provider "talos" {}

provider "tailscale" {}

provider "helm" {}
