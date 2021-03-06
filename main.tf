# -------------------------------------------------------------
# File Name: main.tf
# Deploy a new VM from a template.
#
# REQUIREMENTS #1: vsphere_tag_category and vsphere_tag must exist
#                  cd helpers/tags && terraform apply
# REQUIREMENTS #2: deploy_vsphere_folder and deploy_vsphere_sub_folder must exist
#                  cd helpers/folders && terraform apply
#
# Tue Nov 2 12:59:12 GMT 2020 - juliusn - initial script
# -------------------------------------------------------------

# -- Provider
provider "vsphere" {
    user                    = var.provider_vsphere_user
    password                = var.provider_vsphere_password
    vsphere_server          = var.provider_vsphere_host
    allow_unverified_ssl    = var.provider_vsphere_unverified_ssl
}

# -------------------------------------------------------------
# Data source definition
# -------------------------------------------------------------

data "vsphere_datacenter" "target_dc" {
    name = var.vsphere_datacenter
}

# Currently, the only exported attribute from vsphere_datastore data source is id, 
# which represents the ID of the datastore that was looked up.

data "vsphere_datastore" "target_datastore" {
    name          = var.vsphere_datastore
    datacenter_id = data.vsphere_datacenter.target_dc.id
}

data "vsphere_compute_cluster" "target_cluster" {
    name          = var.vsphere_cluster
    datacenter_id = data.vsphere_datacenter.target_dc.id
}

data "vsphere_network" "target_network" {
    name          = var.guest_network
    datacenter_id = data.vsphere_datacenter.target_dc.id
}

data "vsphere_virtual_machine" "source_template" {
    name          = "/${var.vsphere_datacenter}/vm/${var.guest_template_folder}/${var.guest_template}"
    datacenter_id = data.vsphere_datacenter.target_dc.id
}

data "vsphere_tag_category" "mycategory" {    
    name = var.guest_category_name
} 

data "vsphere_tag" "tag_category" {    
    name = var.guest_tag_name
    category_id = data.vsphere_tag_category.mycategory.id
} 

data "vsphere_folder" "vm_folder" {
    path = "/${var.vsphere_datacenter}/vm/${var.vsphere_folder}/${var.vsphere_sub_folder}"
}

locals {
    timestamp = formatdate("EEEE, DD-MMM-YYYY hh:mm:ss ZZZ", timestamp())
}

# -------------------------------------------------------------
# Resource definition
# -------------------------------------------------------------
resource "null_resource" "pre_script" {
  provisioner "local-exec" {
    #  20_check_datastore_free_space.ps1 script returns  0 if the datastore has more free space than var.datastore_freespace_limit
    #  20_check_datastore_free_space.ps1 script returns -1 if the datastore has less free space than var.datastore_freespace_limit
    #  Error & Exit if there is not enough free space on the datastore
    command = "./scripts/20_check_datastore_free_space.ps1 ${var.vsphere_datastore} ${var.datastore_freespace_limit}"
    interpreter = ["/bin/pwsh", "-Command"]
  }
}

resource "vsphere_virtual_machine" "myvm" {
    name                = var.guest_vm_name
    resource_pool_id    = data.vsphere_compute_cluster.target_cluster.resource_pool_id
    datastore_id        = data.vsphere_datastore.target_datastore.id
    folder              = "/${var.vsphere_folder}/${var.vsphere_sub_folder}"
    annotation          = "Using template ${var.guest_template} - Created on ${local.timestamp}"
    num_cpus            = var.guest_vcpu
    memory              = var.guest_memory
    guest_id            = data.vsphere_virtual_machine.source_template.guest_id
    nested_hv_enabled   = true
    scsi_type           = data.vsphere_virtual_machine.source_template.scsi_type

    network_interface {
        network_id      = data.vsphere_network.target_network.id
        adapter_type    = data.vsphere_virtual_machine.source_template.network_interface_types[0]
    }

    disk {
        label            = "${var.guest_vm_name}-disk"
        # Using disk0 size from template
        # size             = data.vsphere_virtual_machine.source_template.disks[0].size

        # Using disk0 size from the VM configuration file
        size             = var.guest_disk0_size
        eagerly_scrub    = data.vsphere_virtual_machine.source_template.disks[0].eagerly_scrub
        thin_provisioned = data.vsphere_virtual_machine.source_template.disks[0].thin_provisioned
    }

    clone {
        template_uuid   = data.vsphere_virtual_machine.source_template.id

        customize {
            linux_options {
                host_name = var.guest_vm_name
                domain    = var.guest_domain
            }

            network_interface {
                ipv4_address = var.guest_ipv4_address
                ipv4_netmask = var.guest_ipv4_netmask
            }

            ipv4_gateway    = var.guest_ipv4_gateway
            dns_server_list = [var.guest_dns_servers]
            dns_suffix_list = [var.guest_dns_suffix]
        }
    }

    tags = [
        data.vsphere_tag.tag_category.id
    ]
    depends_on    = [null_resource.pre_script]

    # Measure of safety against an accidental destroy
    # lifecycle {
    #     prevent_destroy = true
    # }
}

resource "null_resource" "post_script" {
  provisioner "local-exec" {
    command = "./scripts/30_email_vm_report.ps1 ${var.provider_vsphere_host} ${var.guest_vm_name}"
    interpreter = ["/bin/pwsh", "-Command"]
  }
  depends_on    = [vsphere_virtual_machine.myvm]
}
