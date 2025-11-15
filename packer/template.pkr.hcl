variable "project_id" {
  type = string
}

variable "image_name" {
  type    = string
  default = "custom-apache-image"
}

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "apache" {
  project_id          = var.project_id
  zone                = "us-central1-a"
  machine_type        = "e2-medium"
  source_image_family = "ubuntu-2204-lts"
  disk_size           = 10
  image_name          = var.image_name
  ssh_username        = "packer"
}

build {
  name    = "apache-image-build"
  sources = ["source.googlecompute.apache"]

  provisioner "shell" {
    inline = [
      "set -e",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apache2",
      "sudo systemctl enable apache2",
      "sudo systemctl stop apache2"
    ]
  }
}
