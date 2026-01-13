module "cubone" {
  source = "./modules/node"

  node_name       = "cubone"
  controlplane    = true
  install_disk    = "/dev/mmcblk0"
  extension_names = ["tailscale"]
  overlay_name    = "rpi_generic"

  cluster_info        = local.cluster_info
  bootstrap_manifests = local.bootstrap_manifests
}

module "growlithe" {
  source = "./modules/node"

  node_name       = "growlithe"
  controlplane    = false
  install_disk    = "/dev/nvme0n1"
  kernel_modules  = [{ name = "zfs" }]
  openebs_nodeid  = "b5103cce"
  extension_names = ["intel-ucode", "tailscale", "zfs"]

  cluster_info        = local.cluster_info
  bootstrap_manifests = local.bootstrap_manifests
}

