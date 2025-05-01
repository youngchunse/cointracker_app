# cointracker_app
# Hello World on GCP with Terraform & Docker

This project deploys a Dockerized "Hello World" app on GCP using a 2-tier architecture with:

- Global HTTP Load Balancer
- Managed Instance Group (autoscaling)
- Docker image (Flask app)
- Infrastructure as Code via Terraform

## Prerequisites

- GCP account & project
- `gcloud` CLI authenticated
- Docker
- Terraform

## Steps

### 1. Build & Push Docker Image
```bash
cd app
docker build -t gcr.io/YOUR_PROJECT_ID/hello-world:latest .
docker push gcr.io/YOUR_PROJECT_ID/hello-world:latest
