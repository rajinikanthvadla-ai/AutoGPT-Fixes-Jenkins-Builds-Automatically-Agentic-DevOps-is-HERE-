# AI-Powered Self-Healing CI/CD Pipeline

This project implements an AI-powered self-healing CI/CD pipeline using Jenkins, HuggingFace API, and Slack notifications.

## Prerequisites

- AWS EC2 instance (Ubuntu 20.04 or later)
- Docker and Docker Compose
- Jenkins
- Node.js
- Python 3.x
- HuggingFace API key
- Slack webhook URL
- GitHub repository with test failures

## Setup Instructions

1. Launch an AWS EC2 instance:
   - Use Ubuntu 20.04 LTS
   - Minimum t2.medium instance type
   - Open ports 22 (SSH), 8080 (Jenkins), and 5000 (AI service)

2. Run the setup script:
   ```bash
   chmod +x setup_ec2.sh
   ./setup_ec2.sh
   ```

3. Configure Jenkins:
   - Access Jenkins at http://<EC2_PUBLIC_IP>:8080
   - Install suggested plugins
   - Create credentials for:
     - HuggingFace API key
     - Slack webhook URL
     - GitHub token

4. Create a new Jenkins pipeline:
   - Select "Pipeline script from SCM"
   - Choose Git
   - Enter your repository URL
   - Set branch to main
   - Script path: Jenkinsfile

5. Set up environment variables:
   ```bash
   echo "HUGGINGFACE_API_KEY=your_api_key" > .env
   echo "GITHUB_TOKEN=your_github_token" >> .env
   echo "SLACK_WEBHOOK_URL=your_webhook_url" >> .env
   ```

## How It Works

1. Jenkins runs the test suite
2. If tests fail:
   - Logs are sent to HuggingFace API for analysis
   - AI suggests fixes for test failures
   - Fixes are automatically applied and pushed to GitHub
   - Slack notifications are sent for both failures and fixes

3. The AI remediator:
   - Analyzes test failure logs
   - Identifies simple fixes (assertion mismatches, expected values)
   - Applies fixes and commits with descriptive messages
   - Pushes changes to GitHub

## Slack Notifications

The pipeline sends two types of Slack notifications:

1. Failure Notification:
   ```
   ❌ *Build Failed*
   - Build URL
   - Error Log
   ```

2. Fix Notification:
   ```
   🤖 *AI Auto-Fix Applied*
   - Build URL
   - Fixed Files
   ```

## Git Commit Messages

The AI generates descriptive commit messages with emojis:
```
🤖 Auto-fix: Corrected test assertion in calculator.spec.js
```

## Troubleshooting

1. Check Jenkins logs:
   ```bash
   sudo tail -f /var/log/jenkins/jenkins.log
   ```

2. Verify Docker containers:
   ```bash
   docker ps
   ```

3. Check AI service logs:
   ```bash
   docker logs ai-remediator
   ```

## Security Considerations

- Store sensitive credentials in Jenkins credentials store
- Use environment variables for API keys
- Implement proper IAM roles for AWS
- Regularly update dependencies
- Monitor API usage and costs 