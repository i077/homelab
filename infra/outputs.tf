output "installer_urls" {
  value = {
    cubone    = module.image_cubone.installer_url
    growlithe = module.image_growlithe.installer_url
  }
}
