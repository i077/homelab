data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.cluster_info.talos_version
  filters       = { names = var.extension_names }
}

data "talos_image_factory_overlays_versions" "this" {
  count = var.overlay_name != null ? 1 : 0

  talos_version = var.cluster_info.talos_version
  filters       = { name = var.overlay_name }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(merge(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    },
    var.overlay_name != null ? {
      overlay = {
        name  = data.talos_image_factory_overlays_versions.this[0].overlays_info[0].name
        image = data.talos_image_factory_overlays_versions.this[0].overlays_info[0].image
      }
    } : {}
  ))
}

data "talos_image_factory_urls" "this" {
  talos_version = var.cluster_info.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "metal"
}
