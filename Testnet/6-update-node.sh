#!/bin/bash

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Please enter the firedancer version number (e.g., v1.16.19):"
    echo "usage $0 [version]"
    exit 1
fi

# Start the Service
echo "stopping the firedancer service"
systemctl stop firedancer-validator.service

#Build

./3-build.sh $VERSION

# Start the Service
echo "starting the firedancer service"
systemctl start firedancer-validator.service
