module "image_cubone" {
  source = "./modules/image-factory"

  talos_version   = local.talos_version
  extension_names = ["tailscale"]
  overlay_name    = "rpi_generic"
}

# Control plane
resource "talos_machine_configuration_apply" "cubone" {
  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = "cubone"

  config_patches = [
    jsonencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      hostname   = "cubone"
      auto       = "off"
    }),
    jsonencode({
      machine = {
        install = {
          disk  = "/dev/mmcblk0"
          image = module.image_cubone.installer_url
        }
      }
    }),
    local.kubelet_ca_patch,
    local.tailnet_patch,
    local.cluster_config_patch,
    local.cluster_domain_patch,
    local.cni_patch_controlplane,
    local.cni_patch
  ]
}

module "image_growlithe" {
  source = "./modules/image-factory"

  talos_version   = local.talos_version
  extension_names = ["intel-ucode", "tailscale", "zfs"]
}

resource "random_id" "growlithe" {
  byte_length = 4
}

# Data plane
resource "talos_machine_configuration_apply" "growlithe" {
  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = "growlithe"

  config_patches = [
    jsonencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      hostname   = "growlithe"
      auto       = "off"
    }),
    jsonencode({
      machine = {
        install = {
          disk  = "/dev/nvme0n1"
          image = module.image_growlithe.installer_url
        }
        kernel = {
          modules = [{ name = "zfs" }]
        }

        nodeLabels = {
          "openebs.io/nodeid" = random_id.growlithe.hex
        }
      }
    }),
    local.kubelet_ca_patch,
    local.tailnet_worker_patch,
    local.cluster_domain_patch,
    local.cni_patch
  ]
}
