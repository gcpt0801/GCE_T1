terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
  }
  backend "gcs" {
    bucket = "gcp-tftbk"
    prefix = "T1/state"
  }
}
provider "google" {
  project = "gcp-terraform-demo-474514"
  region  = "us-central1"
  zone    = "us-central1-a"
}
