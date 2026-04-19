# Defining VM Volume
resource "libvirt_volume" "base" {
  name   = "ubuntu-base.qcow2"
  pool   = "images"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}
    
resource "libvirt_volume" "ubuntu-qcow2" {
  name           = "ubuntu.qcow2"
  pool           = "images"
  base_volume_id = libvirt_volume.base.id
  size           = 16106127360
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  pool = "images" # List storage pools using virsh pool-list
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_key = file("~/.ssh/id_rsa.pub")
  })

  meta_data = <<EOF
instance-id: ubuntu-01
local-hostname: ubuntu
EOF
}

# Define KVM domain to create
resource "libvirt_domain" "ubuntu" {
  name   = "ubuntu"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_name = "default" # List networks with virsh net-list
    wait_for_lease = true
  }

  disk {
    volume_id = "${libvirt_volume.ubuntu-qcow2.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Output Server IP
output "ip" {
  value = "${libvirt_domain.ubuntu.network_interface.0.addresses.0}"
}
