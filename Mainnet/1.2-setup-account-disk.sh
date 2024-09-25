#!/bin/bash -xe

# Display the block devices
lsblk

# Create a RAID 0 array for the given NVMe drives for firedancer-accounts
mdadm --create --force /dev/md1 --level=0 --raid-devices=2 \
        /dev/nvme2n1 \
        /dev/nvme3n1

# Format the RAID array to ext4
mkfs.ext4 -F /dev/md1

mkdir -pv /mnt/disk2

# mount the disk
sudo mount /dev/md1 /mnt/disk2

# create firedancer-accounts dir and set permissions
sudo mkdir -pv /mnt/disk2/firedancer-accounts
sudo chown firedancer:firedancer -R /mnt/disk2/firedancer-accounts
sudo chmod 0775 -R /mnt/disk2/firedancer-accounts

# mount /mnt/disk2/firedancer-accounts unto /opt/firedancer-accounts
sudo mkdir -pv /opt/firedancer-accounts
sudo mount --bind /mnt/disk2/firedancer-accounts /opt/firedancer-accounts

# add mounts to fstab
sudo cp /etc/fstab /etc/fstab.bak
echo "/dev/md1 /mnt/disk2 ext4 defaults 0 0" | sudo tee -a /etc/fstab
echo "/mnt/disk2/firedancer-accounts /opt/firedancer-accounts none bind 0 0" | sudo tee -a /etc/fstab
