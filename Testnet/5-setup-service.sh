#!/bin/bash -xe

echo "Running as $USER"

# Check if script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Running as sudo: $SUDO_USER"

# ----------------------------
# System Configuration for Firedancer
# ----------------------------

# Set required system settings for Firedancer
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.rmem_default=134217728
sysctl -w net.core.wmem_max=134217728
sysctl -w net.core.wmem_default=134217728
sysctl -w vm.max_map_count=1000000
sysctl -w fs.nr_open=1000000
sysctl -w net.ipv4.tcp_rmem='65536 134217728 134217728'
sysctl -w net.ipv4.tcp_wmem='65536 134217728 134217728'
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.core.netdev_max_backlog=10000

# Persist system settings by adding them to /etc/sysctl.conf
echo "net.core.rmem_max=134217728" | tee -a /etc/sysctl.conf
echo "net.core.rmem_default=134217728" | tee -a /etc/sysctl.conf
echo "net.core.wmem_max=134217728" | tee -a /etc/sysctl.conf
echo "net.core.wmem_default=134217728" | tee -a /etc/sysctl.conf
echo "vm.max_map_count=1000000" | tee -a /etc/sysctl.conf
echo "fs.nr_open=1000000" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_rmem=65536 134217728 134217728" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem=65536 134217728 134217728" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf
echo "net.core.netdev_max_backlog=10000" | tee -a /etc/sysctl.conf

# Apply the settings
sysctl -p

# Increase file descriptor limits
echo "* soft nofile 1000000" | tee -a /etc/security/limits.conf
echo "* hard nofile 1000000" | tee -a /etc/security/limits.conf

# ----------------------------
# Firedancer Initialization (fdctl)
# ----------------------------

# Perform Firedancer system configuration using fdctl
/opt/firedancer/build/<version>/fdctl configure init all

# Ensure hugetlbfs is re-mounted after reboot using rc.local (for example)
if ! grep -q "/opt/firedancer/build/<version>/fdctl configure init hugetlbfs" /etc/rc.local; then
    echo "/opt/firedancer/build/<version>/fdctl configure init hugetlbfs" | tee -a /etc/rc.local
fi

# Make rc.local executable (if not already)
/bin/chmod +x /etc/rc.local

# ----------------------------
# Validator Setup Script
# ----------------------------

# Create a startup script for firedancer Validator using Firedancer
tee /usr/local/bin/start-firedancer.sh > /dev/null <<EOF
#!/bin/bash

/usr/local/bin/agave-validator \\
    --enable-extended-tx-metadata-storage \\
    --no-voting \\
    --port-check true \\
    --no-poh-speed-test \\
    --log - \\
    --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \\
    --identity /opt/firedancer/validator-keypair.json \\
    --entrypoint entrypoint.mainnet-beta.firedancer.com:8001 \\
    --entrypoint entrypoint2.mainnet-beta.firedancer.com:8001 \\
    --entrypoint entrypoint3.mainnet-beta.firedancer.com:8001 \\
    --known-validator 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on \\
    --known-validator dDzy5SR3AXdYWVqbDEkVFdvSPCtS9ihF5kJkHCtXoFs \\
    --known-validator Ft5fbkqNa76vnsjYNwjDZUXoTWpP7VYm3mtsaQckQADN \\
    --known-validator eoKpUABi59aT4rR9HGS3LcMecfut9x7zJyodWWP43YQ \\
    --known-validator 9QxCLckBiJc783jnMvXZubK4wH86Eqqvashtrwvcsgkv \\
    --wal-recovery-mode skip_any_corrupted_record \\
    --only-known \\
    --ledger /opt/firedancer/ledger \\
    --limit-size 200000000 \\
    --rpc-bind-address 127.0.0.1 \\
    --port 8899 \\
    --private-rpc \\
    --enable-rpc-transaction-history \\
    --full-rpc-api \\
    --accounts /opt/firedancer-accounts \\
    --minimal-snapshot-download-speed 250000000
EOF

# Make the startup script executable
chmod +x /usr/local/bin/start-firedancer.sh

# ----------------------------
# Systemd Service Setup
# ----------------------------

# Create a systemd service for the firedancer Validator
tee /etc/systemd/system/firedancer-validator.service > /dev/null <<EOF
[Unit]
Description=firedancer Validator
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/start-firedancer.sh
User=firedancer
Restart=on-failure
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF

# Reload systemd manager configuration
systemctl daemon-reload

# Enable the firedancer Validator service
systemctl enable firedancer-validator.service

echo "firedancer validator service created."
echo "Run 'systemctl start firedancer-validator' to start the service."
