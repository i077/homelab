output "installer_urls" {
  value = {
    cubone    = module.cubone.installer_url
    growlithe = module.growlithe.installer_url
  }
}

output "talos_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}