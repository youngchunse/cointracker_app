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
cd app
docker build -t gcr.io/hello-world-python-app-458519/hello-world:latest .
docker push gcr.io/hello-world-python-app-458519/hello-world:latest

### 2. Create Terraform Infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

### 3. Access Application
curl http://<load_balancer_ip>

### 4. Cleanup Environment
terraform destroy
