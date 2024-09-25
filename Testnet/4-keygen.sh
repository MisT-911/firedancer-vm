#!/bin/bash -xe

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Create Keypair file
solana-keygen new --outfile /opt/firedancer/validator-keypair.json
chmod 600 /opt/firedancer/validator-keypair.json
chown firedancer:firedancer /opt/firedancer/validator-keypair.json