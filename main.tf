data "ibm_resource_group" "resource_group" {
  name = "Default"
}

resource "ibm_is_vpc" "vpc" {
  name = "${var.vpc_name}-vpc"
  default_network_acl_name    = "${var.vpc_name}-edge-acl"
  default_security_group_name = "${var.vpc_name}-default-sg"
  default_routing_table_name  = "${var.vpc_name}-default-table"
  no_sg_acl_rules             = false
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.vpc_name}-subnet"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zone
  total_ipv4_address_count = 256
}

# Resource to create COS instance if create_cos_instance is true
resource "ibm_resource_instance" "cos_instance" {
  name              = var.cos_name
  # resource_group_id = var.resource_group_id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_container_vpc_cluster" "cluster" {
  name              = "${var.vpc_name}-cluster-dn"
  vpc_id            = ibm_is_vpc.vpc.id
  # kube_version      = "4.17.28_openshift"
  worker_count      = 1
  resource_group_id = data.ibm_resource_group.resource_group.id
  flavor            = "bx2.16x64"
  disable_public_service_endpoint = false
  cos_instance_crn  = ibm_resource_instance.cos_instance.id
  zones {
    subnet_id = ibm_is_subnet.subnet.id
    name      = var.zone
  }
  entitlement = var.ocp_entitlement

}
