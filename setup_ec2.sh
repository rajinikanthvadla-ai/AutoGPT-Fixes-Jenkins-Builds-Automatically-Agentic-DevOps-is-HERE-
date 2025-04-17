#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting AWS EC2 setup for AI-powered CI/CD pipeline..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    unzip \
    awscli

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Jenkins
echo "🔧 Installing Jenkins..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install -y jenkins

# Add Jenkins to Docker group
echo "👥 Adding Jenkins to Docker group..."
sudo usermod -aG docker jenkins

# Install Node.js
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Python and required packages
echo "🐍 Installing Python and dependencies..."
sudo apt-get install -y python3 python3-pip python3-venv
sudo pip3 install requests python-dotenv

# Create necessary directories
echo "📁 Creating necessary directories..."
sudo mkdir -p /var/jenkins_home/workspace
sudo mkdir -p /opt/ai-pipeline
sudo chown -R jenkins:jenkins /var/jenkins_home
sudo chown -R jenkins:jenkins /opt/ai-pipeline

# Configure AWS CLI
echo "🔑 Configuring AWS CLI..."
mkdir -p ~/.aws
cat > ~/.aws/config << EOL
[default]
region = us-east-1
output = json
EOL

# Set up environment variables
echo "🔧 Setting up environment variables..."
cat > /opt/ai-pipeline/.env << EOL
# 🔐 Slack Integration
SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}
SLACK_APP_TOKEN=${SLACK_APP_TOKEN}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
SLACK_CHANNEL=${SLACK_CHANNEL}

# 🤖 HuggingFace LLM API
HUGGINGFACE_API_KEY=${HUGGINGFACE_API_KEY}
HUGGINGFACE_MODEL=${HUGGINGFACE_MODEL}
HUGGINGFACE_API_URL=${HUGGINGFACE_API_URL}

# 🔒 Security
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}

# 🌐 Network
DOCKER_REGISTRY=${DOCKER_REGISTRY}
KUBE_CONFIG=${KUBE_CONFIG}

# 📊 Monitoring
PROMETHEUS_URL=${PROMETHEUS_URL}
GRAFANA_URL=${GRAFANA_URL}
EOL

# Set permissions
sudo chown -R jenkins:jenkins /opt/ai-pipeline
sudo chmod 600 /opt/ai-pipeline/.env

# Start services
echo "🚀 Starting services..."
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow 22
sudo ufw allow 8080
sudo ufw allow 5000
sudo ufw --force enable

# Print completion message
echo "✅ Setup completed! Please note the following:"
echo "1. Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "2. Jenkins will be available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "3. AI Remediation service will be available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000"
echo "4. Environment variables have been configured in /opt/ai-pipeline/.env"
echo "5. Firewall has been configured to allow necessary ports" 