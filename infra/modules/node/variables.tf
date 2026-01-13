variable "node_name" {
  type        = string
  description = "Name of this node"
}

variable "node_endpoint" {
  type        = string
  default     = null
  description = "Domain or IP address of the node. If not set, node_name will be used."
}

variable "controlplane" {
  type        = bool
  description = "Whether this node is a control plane node"
}

variable "extension_names" {
  type        = list(string)
  description = "Names of talos extensions to include"
}

variable "overlay_name" {
  type        = string
  description = "Name of overlay"
  default     = null
}

variable "install_disk" {
  type        = string
  description = "Disk to use for installations"
}

variable "kernel_modules" {
  type = list(object({
    name       = string
    parameters = optional(list(string))
  }))
  default = []
}

variable "openebs_nodeid" {
  type        = string
  default     = null
  description = <<-EOT
    Persistent ID for OpenEBS to identify volumes that were attached to this node.
    If not set, no label will be applied.
  EOT
}

variable "cluster_info" {
  type = object({
    cluster_name         = string
    cluster_endpoint     = string
    talos_version        = string
    kubernetes_version   = string
    machine_secrets      = any
    client_configuration = map(any)
    tailnet_auth_key     = string
  })
  description = "Cluster info and other values common across all nodes"
}

variable "bootstrap_manifests" {
  type = object({
    cilium_cni  = string
    gateway_api = string
  })
  description = "Manifests to apply on bootstrap"
}

