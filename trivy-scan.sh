#!/bin/bash
set -e

IMAGE_NAME="devops/taskapp:latest"

echo "Building image for vulnerability scanning..."
docker build -t ${IMAGE_NAME} .

echo "Running Trivy vulnerability scanner (HIGH and CRITICAL)..."
# Using the Trivy Docker image so that Trivy does not need to be installed on the host machine
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.cache/trivy:/root/.cache/ \
  aquasec/trivy image \
  --timeout 30m \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  ${IMAGE_NAME}
