output "spinnaker_sa_key" {
  value     = google_service_account_key.spinnaker.private_key
  sensitive = true
}

output "spinnaker_gcb_subscription" {
  value = google_pubsub_subscription.spinnaker_gcb.name
}

output "artifacts_storage_bucket" {
  value = google_storage_bucket.artifacts.name
}

output "source_repository_url" {
  value = google_sourcerepo_repository.sampleapp.url
}

output "gke_cluster_name" {
  value = google_container_cluster.cluster.name
}

output "gke_cluster_location" {
  value = google_container_cluster.cluster.location
}
