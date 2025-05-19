#!/bin/bash

# Log output to a file for debugging
exec > /var/log/startup-script.log 2>&1
set -x

echo "Beginning startup script"

# Update package lists
apt-get update

# Install Docker and Google Cloud SDK
apt-get install -y docker.io google-cloud-sdk

# Start Docker service
systemctl start docker

# Authenticate Docker to GCR
gcloud auth configure-docker --quiet

# Pull Docker image
docker pull gcr.io/hello-world-python-app-458519/hello-world:latest

# Run Docker container
docker run -d -p 80:80 gcr.io/hello-world-python-app-458519/hello-world:latest
