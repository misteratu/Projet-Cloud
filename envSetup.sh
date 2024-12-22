#!/bin/bash
# Ce script configure l'environnement de virtualisation sur une machine Ubuntu 24.04 LTS sans utiliser le playbook Ansible.

set -e  # Arrêter en cas d'erreur

# Mettre à jour les paquets
echo "Mise à jour des paquets..."
sudo apt update

# Installer les paquets nécessaires
echo "Installation des paquets nécessaires..."
sudo apt install -y openssh-server qemu-kvm libvirt-daemon-system libvirt-clients \
  bridge-utils virt-manager gnupg software-properties-common guestfs-tools

# Ajouter la clé GPG de HashiCorp si absente
if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
  echo "Ajout de la clé GPG de HashiCorp..."
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
fi

# Ajouter le dépôt HashiCorp
if ! grep -q "hashicorp" /etc/apt/sources.list.d/hashicorp.list 2>/dev/null; then
  echo "Ajout du dépôt HashiCorp..."
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
fi

# Mettre à jour la liste des paquets après ajout du dépôt
echo "Mise à jour après ajout du dépôt..."
sudo apt update

# Installer Terraform
echo "Installation de Terraform..."
sudo apt install -y terraform

# Ajouter des paramètres à la fin de qemu.conf
echo "Configuration de /etc/libvirt/qemu.conf..."
sudo tee -a /etc/libvirt/qemu.conf > /dev/null <<EOL
user = "libvirt-qemu"
group = "kvm"
security_driver = "none"
EOL

# Redémarrer le service libvirtd
echo "Redémarrage du service libvirtd..."
sudo systemctl restart libvirtd

# Accorder les permissions au dossier contenant les images des VM
echo "Mise à jour des permissions sur /var/lib/libvirt/images..."
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images
sudo chmod 770 /var/lib/libvirt/images

# Créer le dossier pour la pool
if [ ! -d /home/n7/pool ]; then
  echo "Création du dossier pour la pool..."
  sudo mkdir -p /home/n7/pool
  sudo chown libvirt-qemu:kvm /home/n7/pool
  sudo chmod 770 /home/n7/pool
fi

# Définir, construire et activer la pool 'mypool'
if ! virsh pool-info mypool >/dev/null 2>&1; then
  echo "Définition et activation de la pool 'mypool'..."
  sudo virsh pool-define-as mypool dir - - - - "/home/n7/pool"
  sudo virsh pool-build mypool
  sudo virsh pool-start mypool
  sudo virsh pool-autostart mypool
fi

# Télécharger l'image Ubuntu dans la pool
if [ ! -f /var/lib/libvirt/images/noble-server-cloudimg-amd64.img ]; then
  echo "Téléchargement de l'image Ubuntu..."
  sudo wget -O /var/lib/libvirt/images/noble-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
  sudo chmod 777 /var/lib/libvirt/images/noble-server-cloudimg-amd64.img
fi

# Configurer le mot de passe root de l'image Ubuntu
echo "Configuration du mot de passe root de l'image Ubuntu..."
sudo virt-customize -a /var/lib/libvirt/images/noble-server-cloudimg-amd64.img --root-password password:ubuntu

echo "Configuration terminée avec succès."
