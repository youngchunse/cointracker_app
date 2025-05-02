#!/bin/bash
apt-get update && apt-get install -y docker.io
systemctl start docker
docker run -d -p 80:80 gcr.io/hello-world-python-app-458519/hello-world:latest