#!/bin/bash -xe

echo running as $USER

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo running as sudo: $SUDO_USER

useradd -r -s /bin/false firedancer

usermod -aG firedancer firedancer
usermod -aG firedancer $SUDO_USER
usermod -aG systemd-journal $SUDO_USER

# Create Solana data directory
mkdir -pv /opt/firedancer
# Create directory for ledger
mkdir -p /opt/firedancer/ledger

chown -R firedancer:firedancer /opt/firedancer
chmod -R 775 /opt/firedancer

# refresh the groups
newgrp systemd-journal
newgrp solana