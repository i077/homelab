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
      kind       = "UnattendedInstallConfig"
      installer = {
        image = data.talos_image_factory_urls.this.urls.installer
      }
      provisioning = {
        diskSelector = {
          match = format("disk.dev_path == %s", jsonencode(var.install_disk))
        }
      }
    }),
    jsonencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      hostname   = var.node_name
      auto       = "off"
    }),
    jsonencode({
      machine = {
        kernel = {
          modules = var.kernel_modules
        }
      }
    }),
    local.kubelet_ca_patch,
    local.tailnet_patch,
    local.resolver_patch,
    local.kube_network_patch,
    local.cni_patch,
    ],
    var.controlplane ? [
      local.cni_install_patch,
      local.cluster_config_patch,
      local.kube_apiserver_patch,
      local.kube_proxy_patch,
      local.flannel_delete_patch,
      local.talos_api_access_patch,
    ] : [],
  )
}
