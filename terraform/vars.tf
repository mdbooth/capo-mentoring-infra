variable "env_name" {
  default = "mbooth-test"
}

variable "location" {
  default = "uksouth"
}

variable "bootstrap_github_ssh_key" {
  default = "mdbooth"
}

variable "address_space" {
  default = "192.168.224.0/21"
}

variable "hosts" {
  type = list(object({
    size        = string
    extra_disks = list(number)
  }))
  default = [{
    size        = "Standard_E2as_v5"
    extra_disks = [500]
  }]
}

data "curl" "bootstrap_github_ssh_key" {
  uri         = format("https://github.com/%s.keys", var.bootstrap_github_ssh_key)
  http_method = "GET"
}

locals {
  external_cidr     = cidrsubnet(var.address_space, 3, 0)
  internal_cidr     = cidrsubnet(var.address_space, 3, 1)
  bootstrap_ssh_key = data.curl.bootstrap_github_ssh_key.response
}
