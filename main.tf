 
# module "vpc" {
#   source                  = "./modules/vpc"
#   version                 = "~> 2.0.0"
  
#   project_id              = var.project_id
#   network_name            = var.network_name

#   auto_create_subnetworks = var.auto_create_subnetworks
#   routing_mode            = var.routing_mode
#   description             = var.description
#   shared_vpc_host         = var.shared_vpc_host
# }

# /******************************************
# 	Subnet configuration
#  *****************************************/
# module "subnets" {
#   source           = "./modules/subnets"
#   project_id       = var.project_id
#   network_name     = module.vpc.network_name
#   subnets          = var.subnets
#   secondary_ranges = var.secondary_ranges
# }

# /******************************************
# 	Routes
#  *****************************************/
# module "routes" {
#   source                                 = "./modules/routes"
#   project_id                             = var.project_id
#   network_name                           = module.vpc.network_name
#   routes                                 = var.routes
#   delete_default_internet_gateway_routes = var.delete_default_internet_gateway_routes
#   module_depends_on                      = [module.subnets.subnets]
# }

provider "google" {
 credentials = "${file("${var.credentials}")}"
 project     = "${var.gcp_project}" 
 region      = "${var.region}"
}


module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.0"

    project_id   = "${var.project_id}"
    network_name = "${var.network_name}"
    routing_mode            = "${var.routing_mode}"
    description             = "${var.description}"
    shared_vpc_host         = "${var.shared_vpc_host}"
    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-central1a"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "us-central1a"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "2nd Subnet"
        },
        {
            subnet_name               = "subnet-03"
            subnet_ip                 = "10.10.30.0/24"
            subnet_region             = "us-central1a"
            # subnet_flow_logs          = "true"
            # subnet_flow_logs_interval = "INTERVAL_10_MIN"
            # subnet_flow_logs_sampling = 0.7
            # subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
        }
    ]

    secondary_ranges = {
        subnet-01 = [
            {
                range_name    = "subnet-01-secondary-01"
                ip_cidr_range = "192.168.64.0/24"
            },
        ]

        subnet-02 = []
    }

    routes = [
        {
            name                   = "routes-1"
            destination_range      = "0.0.0.0/0"
            tags                   = "egress-inet"
            next_hop_internet      = "true"
        },
        {
            name                   = "routes-2"
            description            = "route_through_proxy_to_reach_app"
            destination_range      = "10.50.10.0/24"
            tags                   = "app-proxy"
            next_hop_instance      = "app-proxy-instance"
            next_hop_instance_zone = "us-central1a"
        },
    ]
}

resource "google_compute_router" "foobar" {
  name    = "my-router"
  network = google_compute_network.foobar.name
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "1.2.3.4"
    }
    advertised_ip_ranges {
      range = "6.7.0.0/16"
    }
  }
}

resource "google_compute_network" "foobar" {
  name                    = "my-network"
  auto_create_subnetworks = false
}


module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  project_id                         = "${var.project_id}"
  region                             = "${var.region}"
  router                             = "${var.router_name}"
  name                               = "my-cloud-nat-${var.router_name}"
  # nat_ips                            = var.nat_addresses
  min_ports_per_vm                   = "128"
  icmp_idle_timeout_sec              = "15"
  tcp_established_idle_timeout_sec   = "600"
  tcp_transitory_idle_timeout_sec    = "15"
  udp_idle_timeout_sec               = "15"
  source_subnetwork_ip_ranges_to_nat = "${var.source_subnetwork_ip_ranges_to_nat}"
  # subnetworks                        = var.subnetworks
}