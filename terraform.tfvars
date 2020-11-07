# -------------------------------------------------------------
# File Name: teraform.tfvars
# Defining simple variables and credentials required for VM deployment
#
# Tue Nov 3 12:59:12 BST 2020 - juliusn - initial script
# -------------------------------------------------------------

# -------------------------------------------------------------
# PROVIDER - VMware vSphere vCenter settings 
# -------------------------------------------------------------
#
# Avoid storing screts in plain text
# Instead pass in a value for each variable foo by setting an environment variable called TF_VAR_foo.
#
# provider_vsphere_host = "example.flexlab.local"
# provider_vsphere_user = "user@flexlab.local"
# provider_vsphere_password = "password"
# provider_vsphere_unverified_ssl = "true"

# -------------------------------------------------------------
# INFRASTRUCTURE - VMware vSphere vCenter settings 
# -------------------------------------------------------------
vsphere_datacenter = "EAST-DC"
vsphere_cluster = "EAST-Cluster"
vsphere_datastore = "vsanDatastore"
vsphere_folder = "Production"
vsphere_sub_folder = "Applications"

# -------------------------------------------------------------
# GUEST - VMware vSphere VM settings 
# -------------------------------------------------------------
guest_template = "CentOS7-Template-noX"
guest_id = "centos64Guest"
guest_template_folder = "Templates"
guest_vm_name = "nat-web01"
guest_vcpu = "1"
guest_memory = "4096"
guest_disk0_size = "30"
guest_network = "lab-mgmt"
guest_ipv4_address = "192.168.111.49"
guest_ipv4_netmask = "24"
guest_ipv4_gateway = "192.168.111.1"
guest_dns_servers = "192.168.111.111"
guest_dns_suffix = "flexlab.local"
guest_domain = "flexlab.local"

guest_category_name = "CUSTOM-CATEGORY"
guest_tag_name = "CUSTOM-TAG"