#!/bin/bash -xe

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Please enter the Firedancer version number (e.g., v0.1):"
    echo "usage: $0 [version]"
    exit 1
fi

echo "Attempting to build Firedancer Version $VERSION"

# Update and upgrade the system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install necessary dependencies
sudo apt-get install -y git cmake clang ninja-build build-essential pkg-config libssl-dev libudev-dev llvm

# Ensure GCC version 11 or higher is installed
gcc_version=$(gcc -dumpversion | cut -f1 -d.)
if [ "$gcc_version" -lt 11 ]; then
    echo "GCC version is less than 11. Installing GCC-11..."
    sudo apt-get install -y gcc-11 g++-11
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 60
else
    echo "GCC version is $gcc_version, which is sufficient."
fi

# Set LLVM and Clang paths (if different from default, update these)
export LLVM_VERSION=14
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/lib/x86_64-linux-gnu/pkgconfig/libudev.pc
export LIBCLANG_PATH=/usr/lib/llvm-$LLVM_VERSION/lib/libclang.so

# Verify necessary files
if [ ! -f "/usr/lib/x86_64-linux-gnu/pkgconfig/libudev.pc" ]; then
    echo "File does not exist: /usr/lib/x86_64-linux-gnu/pkgconfig/libudev.pc"
    exit 1
fi

if [ ! -f "/usr/lib/llvm-$LLVM_VERSION/lib/libclang.so" ]; then
    echo "File does not exist: /usr/lib/llvm-$LLVM_VERSION/lib/libclang.so"
    exit 1
fi

# Install Rust if it's not installed
if ! command -v rustc &> /dev/null; then
    echo "Rust not found, installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal
    source $HOME/.cargo/env
else
    echo "Rust is already installed."
fi

# Clone the Firedancer repository and build from source
git clone https://github.com/firedancer-io/firedancer.git /opt/firedancer/build/$VERSION
cd /opt/firedancer/build/$VERSION
git fetch
git checkout $VERSION

# Build Firedancer with fdctl and Solana components
cmake -B build
cmake --build build --config Release
make -j fdctl solana  # This line ensures that both fdctl and Solana components are built

# Remove previous versions if they exist
sudo rm -f "/usr/local/bin/firedancer-validator"
sudo rm -f "/usr/local/bin/fdctl"

sudo chown -R firedancer:firedancer /opt/firedancer/build

# Move Binaries to /usr/local/bin
sudo ln -s /opt/firedancer/build/$VERSION/build/fd_validator /usr/local/bin/firedancer-validator
sudo ln -s /opt/firedancer/build/$VERSION/build/fdctl /usr/local/bin/fdctl

echo "Firedancer Validator and fdctl are now installed and linked to /usr/local/bin"
