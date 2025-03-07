locals {
  tailnet_patch = jsonencode({
    apiVersion  = "v1alpha1"
    kind        = "ExtensionServiceConfig"
    name        = "tailscale"
    environment = ["TS_AUTHKEY=${tailscale_tailnet_key.tsauth.key}", "TS_ACCEPT_DNS=true", "TS_EXTRA_ARGS=--reset"]
  })

  # Replace CNI & kube-proxy with Cilium
  cni_patch_controlplane = jsonencode({
    cluster = {
      inlineManifests = [{ name = "cilium", contents = data.helm_template.cilium.manifest }]
    }
  })

  cni_patch = jsonencode({
    machine = {
      features = {
        hostDNS = {
          enabled = true
          # Disable forwarding DNS to host, since this is incompatible with Cilium:
          # https://www.talos.dev/v1.9/kubernetes-guides/network/deploying-cilium/#known-issues
          forwardKubeDNSToHost = false
        }
      }
    }

    cluster = {
      proxy = { disabled = true }
      network = {
        cni = { name = "none" }
      }
    }
  })

  cluster_config_patch = jsonencode({
    machine = {
      certSANs = [local.cluster_endpoint]
    }
    cluster = {
      apiServer = {
        certSANs = [local.cluster_endpoint]
      }
    }
  })

  cluster_domain_patch = jsonencode({
    cluster = {
      network = { dnsDomain = "home.arpa" }
    }
  })

  kubelet_ca_patch = jsonencode({
    machine = {
      kubelet = {
        extraArgs = {
          rotate-server-certificates = true
        }
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
        kernel = {
          modules = [{ name = "zfs" }]
        }
        network = { hostname = "growlithe" }
      }
    }),
    local.kubelet_ca_patch,
    local.tailnet_patch,
    local.cluster_domain_patch,
    local.cni_patch
  ]
}
