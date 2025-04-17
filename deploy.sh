#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting deployment of AI-powered CI/CD pipeline..."

# Make scripts executable
chmod +x setup_ec2.sh
chmod +x generate-ssl.sh

# Run setup script
echo "📦 Running EC2 setup..."
./setup_ec2.sh

# Generate SSL certificates
echo "🔐 Generating SSL certificates..."
./generate-ssl.sh

# Start Docker Compose
echo "🐳 Starting services with Docker Compose..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "🔍 Checking service status..."
docker-compose ps

# Print access information
echo "✅ Deployment completed! Access information:"
echo "1. Jenkins: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/jenkins"
echo "2. AI Remediation API: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/api"
echo "3. Health Check: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health"

# Print next steps
echo "
📝 Next steps:
1. Access Jenkins and complete the initial setup
2. Configure your GitHub repository in Jenkins
3. Set up your pipeline using the Jenkinsfile
4. Test the AI remediation by pushing a failing test
" 