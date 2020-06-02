resource "google_compute_network" "private" {
  provider = google-beta

  name = "metropolis-quickstart"
}

resource "google_compute_global_address" "private_ip" {
  provider = google-beta

  name          = "metropolis-quickstart-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private.self_link
}



resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.private.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}