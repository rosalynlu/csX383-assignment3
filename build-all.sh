#!/usr/bin/env bash
# Build all microservice Docker images.
# Run this script from the PROJECT ROOT:
#   chmod +x build-all.sh
#   ./build-all.sh
#
# To tag for a private registry, set REGISTRY before running:
#   REGISTRY=192.168.1.129:5000/team6 ./build-all.sh

set -e

REGISTRY="${REGISTRY:-}"

tag() {
    local name="$1"
    if [ -n "$REGISTRY" ]; then
        echo "${REGISTRY}/${name}:latest"
    else
        echo "${name}:latest"
    fi
}

echo "==> Building ordering-service..."
docker build -f ordering/Dockerfile -t "$(tag ordering-service)" .

echo "==> Building inventory-service..."
docker build -f inventory/Dockerfile -t "$(tag inventory-service)" .

echo "==> Building pricing-service..."
docker build -f pricing/Dockerfile -t "$(tag pricing-service)" .

echo "==> Building robot-service..."
docker build -f robot/Dockerfile -t "$(tag robot-service)" .

echo ""
echo "All images built successfully:"
docker images | grep -E "ordering-service|inventory-service|pricing-service|robot-service"
