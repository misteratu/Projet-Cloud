variable "vm_count" {
    default = 2
}

variable "vm_memory" {
    default = 1024
}

variable "vm_cpus" {
    default = 1
}

variable "bridge_name" {
    default = "virbr0"
}

variable "image_path" {
    default = "/var/lib/libvirt/images/ubuntu-24.04.qcow2"
}
