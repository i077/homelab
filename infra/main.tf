locals {
  cluster_info = {
    cluster_name     = "homelab"
    cluster_endpoint = "kube.imranh.org"

    talos_version      = "v1.13.0"
    kubernetes_version = "1.36.0"

    machine_secrets      = talos_machine_secrets.this.machine_secrets
    client_configuration = talos_machine_secrets.this.client_configuration
    tailnet_auth_key     = tailscale_tailnet_key.tsauth.key
  }

  bootstrap_manifests = {
    cilium_cni  = data.helm_template.cilium.manifest
    gateway_api = data.http.gateway_api.response_body
  }
}

resource "talos_machine_secrets" "this" {}

resource "tailscale_tailnet_key" "tsauth" {
  reusable      = true
  ephemeral     = false
  preauthorized = false
  description   = "Homelab cluster key"
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_info.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.cluster_info.cluster_endpoint]
}
