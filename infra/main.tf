locals {
  cluster_name     = "homelab"
  cluster_endpoint = "kube.imranh.org"

  k8s_version   = "1.32.3"
  talos_version = "1.9.5"
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = local.talos_version
  kubernetes_version = local.k8s_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = local.talos_version
  kubernetes_version = local.k8s_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.cluster_endpoint]
}

resource "tailscale_tailnet_key" "tsauth" {
  reusable      = true
  ephemeral     = false
  preauthorized = false
  description   = "Homelab cluster key"
  tags          = ["tag:k8s"]
}
