provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  apis = [
    "cloudbuild.googleapis.com",
    "container.googleapis.com",
    "pubsub.googleapis.com",
    "sourcerepo.googleapis.com",
    "storage.googleapis.com",
  ]
}

resource "google_project_service" "api" {
  project            = var.project_id
  for_each           = toset(local.apis)
  service            = each.value
  disable_on_destroy = false
}

data "google_project" "project" {}

resource "google_service_account_key" "spinnaker" {
  service_account_id = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_pubsub_topic" "gcb" {
  name = "cloud-builds"
}

resource "google_pubsub_subscription" "spinnaker_gcb" {
  name  = "spinnaker-gcb"
  topic = google_pubsub_topic.gcb.name
}

resource "google_storage_bucket" "artifacts" {
  name                        = "${var.project_id}-artifacts"
  location                    = var.region
  uniform_bucket_level_access = true
}

resource "google_sourcerepo_repository" "sampleapp" {
  name = "sampleapp"
  depends_on = [
    google_project_service.api
  ]
}

resource "google_cloudbuild_trigger" "main_trigger" {
  location = var.region

  trigger_template {
    branch_name = "master"
    repo_name   = google_sourcerepo_repository.sampleapp.name
  }

  filename = "cloudbuild.yaml"
}

# https://stackoverflow.com/questions/46763287/i-want-to-identify-the-public-ip-of-the-terraform-execution-environment-and-add
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "google_compute_zones" "zones" {}

resource "google_container_cluster" "cluster" {
  name                     = "cluster"
  location                 = data.google_compute_zones.zones.names[0]
  initial_node_count       = 1
  remove_default_node_pool = true
  ip_allocation_policy {}

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${chomp(data.http.myip.body)}/32"
      display_name = "Admin"
    }
  }

  depends_on = [
    google_project_service.api
  ]
}

resource "google_container_node_pool" "pool_01" {
  name       = "pool-01"
  location   = data.google_compute_zones.zones.names[0]
  cluster    = google_container_cluster.cluster.name
  node_count = 3

  node_config {
    machine_type    = "n1-standard-1"
    service_account = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
