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
Test Locally
```bash
cd app
docker build -t hello-world-local .
docker run -d -p 8080:80 hello-world-local
curl http://localhost:8080  # Should print Hello World
```

Push to GCR
```bash
docker tag hello-world-local gcr.io/hello-world-python-app-458519/hello-world:latest
docker push gcr.io/hello-world-python-app-458519/hello-world:latest
```

### 2. Create Terraform Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 3. Access Application
```bash
curl http://<load_balancer_ip>
```

### 4. Cleanup Environment
```bash
terraform destroy
```
