data "talos_machine_configuration" "this" {
  cluster_name       = var.cluster_info.cluster_name
  cluster_endpoint   = format("https://%s:6443", var.cluster_info.cluster_endpoint)
  machine_type       = var.controlplane ? "controlplane" : "worker"
  machine_secrets    = var.cluster_info.machine_secrets
  talos_version      = var.cluster_info.talos_version
  kubernetes_version = var.cluster_info.kubernetes_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_info.cluster_name
  client_configuration = var.cluster_info.client_configuration
  endpoints            = [var.cluster_info.cluster_endpoint]
}

resource "talos_machine_configuration_apply" "this" {
  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  node                        = var.node_name
  endpoint                    = var.node_endpoint

  config_patches = concat([
    jsonencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      hostname   = var.node_name
      auto       = "off"
    }),
    jsonencode({
      machine = {
        install = {
          disk  = var.install_disk
          image = data.talos_image_factory_urls.this.urls.installer
        }
        kernel = {
          modules = var.kernel_modules
        }

        nodeLabels = var.openebs_nodeid != null ? {
          "openebs.io/nodeid" = var.openebs_nodeid
        } : {}
      }
    }),
    local.kubelet_ca_patch,
    local.tailnet_patch,
    local.cluster_domain_patch,
    local.cni_patch,
    ],
    var.controlplane ? [
      local.cni_install_patch,
      local.cluster_config_patch,
      local.talos_api_access_patch,
    ] : [],
  )
}
