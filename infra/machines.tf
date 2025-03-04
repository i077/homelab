locals {
  tailnet_patch = jsonencode({
    apiVersion  = "v1alpha1"
    kind        = "ExtensionServiceConfig"
    name        = "tailscale"
    environment = ["TS_AUTHKEY=${tailscale_tailnet_key.tsauth.key}", "TS_ACCEPT_DNS=true", "TS_EXTRA_ARGS=--reset"]
  })

  cluster_config_patch = jsonencode({
    machine = {
      certSANs = [local.cluster_endpoint]
    }
    cluster = {
      network = { dnsDomain = "home.arpa" }
      apiServer = {
        certSANs = [local.cluster_endpoint]
      }
    }
  })
}

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
  node                        = "192.168.1.163"

  config_patches = [
    jsonencode({
      machine = {
        install = {
          disk  = "/dev/mmcblk0"
          image = module.image_cubone.installer_url
        }
        network = { hostname = "cubone" }
      }
    }),
    local.tailnet_patch,
    local.cluster_config_patch
  ]
}

module "image_growlithe" {
  source = "./modules/image-factory"

  talos_version   = local.talos_version
  extension_names = ["intel-ucode", "tailscale"]
}

# Data plane
resource "talos_machine_configuration_apply" "growlithe" {
  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = "192.168.1.165"

  config_patches = [
    jsonencode({
      machine = {
        install = {
          disk  = "/dev/nvme0n1"
          image = module.image_growlithe.installer_url
        }
        network = { hostname = "growlithe" }
      }
    }),
    local.tailnet_patch,
  ]
}
