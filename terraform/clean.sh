#!/bin/bash

virsh net-undefine bigdata-net
virsh undefine bigdata-vm-0
virsh undefine bigdata-vm-1
virsh undefine bigdata-vm-2
virsh undefine bigdata-vm-3

terraform destroy -auto-approve
terraform refresh

sudo rm -rf ../pool/*