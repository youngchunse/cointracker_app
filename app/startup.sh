#!/bin/bash
apt-get update && apt-get install -y docker.io
systemctl start docker
docker run -d -p 80:5000 gcr.io/$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/project-id)/hello-world:latest
