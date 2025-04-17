pipeline {
    agent any
    
    environment {
        HUGGINGFACE_API_KEY = credentials('huggingface-api-key')
        SLACK_WEBHOOK_URL = credentials('slack-webhook-url')
        GITHUB_TOKEN = credentials('github-token')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    try {
                        sh 'npm test'
                    } catch (error) {
                        // Trigger AI analysis
                        sh '''
                            curl -X POST http://localhost:5000/analyze-failure \
                            -H "Content-Type: application/json" \
                            -H "Authorization: Bearer ${HUGGINGFACE_API_KEY}" \
                            -d '{"log": "$(cat test-results.log)", "repo": "${GIT_URL}"}'
                        '''
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        
        stage('AI Remediation') {
            when {
                expression { currentBuild.result == 'FAILURE' }
            }
            steps {
                script {
                    // Wait for AI to analyze and fix
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Check if fixes were pushed
                    sh '''
                        if git fetch origin && git diff --name-only origin/main | grep -q "test"; then
                            // Notify Slack about the fix
                            curl -X POST ${SLACK_WEBHOOK_URL} \
                            -H 'Content-Type: application/json' \
                            -d '{
                                "text": "🤖 *AI Auto-Fix Applied*",
                                "attachments": [{
                                    "color": "#36a64f",
                                    "fields": [
                                        {
                                            "title": "Build",
                                            "value": "${BUILD_URL}",
                                            "short": true
                                        },
                                        {
                                            "title": "Fixed Files",
                                            "value": "$(git diff --name-only origin/main)",
                                            "short": true
                                        }
                                    ]
                                }]
                            }'
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        failure {
            // Send failure notification to Slack
            sh '''
                curl -X POST ${SLACK_WEBHOOK_URL} \
                -H 'Content-Type: application/json' \
                -d '{
                    "text": "❌ *Build Failed*",
                    "attachments": [{
                        "color": "#ff0000",
                        "fields": [
                            {
                                "title": "Build",
                                "value": "${BUILD_URL}",
                                "short": true
                            },
                            {
                                "title": "Error Log",
                                "value": "$(cat test-results.log | tail -n 20)",
                                "short": false
                            }
                        ]
                    }]
                }'
            '''
        }
    }
} 