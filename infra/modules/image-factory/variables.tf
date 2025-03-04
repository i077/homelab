variable "talos_version" {
  type        = string
  description = "Version of Talos Linux to get extensions for"
}

variable "extension_names" {
  type        = list(string)
  description = "Names of extensions"
}

variable "overlay_name" {
  type    = string
  default = null
}
