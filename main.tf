provider "libvirt" {
    uri = "qemu:///system"
}

resource "libvirt_network" "default" {
    name   = "bigdata-net"
    mode   = "bridge"
    bridge = var.bridge_name
}

resource "libvirt_volume" "disk" {
    count  = var.vm_count
    name   = "vm-disk-${count.index}"
    pool   = "mypool" # Utilisation explicite de la pool mypool
    source = var.image_path
    format = "qcow2"
}

# Fix permissions for the disks after creation
resource "null_resource" "fix_disk_permissions" {
    count = var.vm_count

    provisioner "local-exec" {
        command = <<EOT
        sudo chown libvirt-qemu:kvm /home/n7/pool/vm-disk-${count.index}
        sudo chmod 660 /home/n7/pool/vm-disk-${count.index}
        EOT
    }

    depends_on = [libvirt_volume.disk]
}

resource "libvirt_domain" "vm" {
    count = var.vm_count

    name   = "bigdata-vm-${count.index}"
    memory = var.vm_memory
    vcpu   = var.vm_cpus

    network_interface {
        network_name = libvirt_network.default.name
    }

    disk {
        volume_id = libvirt_volume.disk[count.index].id
    }

    console {
        type        = "pty"
        target_port = "0"
    }

    graphics {
        type        = "vnc"
        listen_type = "address"
    }
}
