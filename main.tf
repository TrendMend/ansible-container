terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
      version = ">=1.1.0"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = ">=0.46.1"
    }
  }
}

module "this" {
  source = "github.com/TrendMend/tf-proxmox-container"

  node_name = var.node_name
  description = var.description
  tags = var.tags
  hostname = var.hostname
  ipv4_address = var.ipv4_address
  ipv4_gateway = var.ipv4_gateway
  ssh_public_key_files = concat(var.ssh_public_key_files, [tls_private_key.this_key.public_key_openssh])
  datastore_id = var.datastore_id
  disk_size = var.disk_size
  cores = var.cores
  memory_dedicated = var.memory_dedicated
  memory_swap = var.memory_swap
  template_file_id = var.template_file_id
  os_type = var.os_type
  nesting = var.nesting
  provision_steps = concat(coalesce(var.provision_steps, []), ["echo done!"])
}

resource "tls_private_key" "this_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "this_key_local" {
  content  = tls_private_key.this_key.private_key_openssh
  filename = ".ssh/${random_uuid.random.result}_rsa"
  file_permission = "0600"
} 

resource "random_uuid" "random" {
}

resource "null_resource" "this_provisioner" {
  triggers = {
    md5 = "${filemd5("${var.playbook_path}")}"
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root  -l ${var.hostname} -i /root/tofu2/ansible/inventory.proxmox.yml --private-key .ssh/${random_uuid.random.result}_rsa --ssh-extra-args '-o UserKnownHostsFile=/dev/null' ${var.playbook_path}"
  }
  depends_on = [ module.this, local_file.this_key_local ]
}