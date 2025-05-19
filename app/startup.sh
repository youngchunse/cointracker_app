#!/bin/bash

# Install Docker
apt-get update
apt-get install -y docker.io google-cloud-sdk

# Authenticate Docker
gcloud auth configure-docker --quiet

# Start Docker
sudo systemctl start docker

# Pull and run image
docker pull gcr.io/hello-world-python-app-458519/hello-world:latest
docker run -d -p 80:80 gcr.io/hello-world-python-app-458519/hello-world:latest