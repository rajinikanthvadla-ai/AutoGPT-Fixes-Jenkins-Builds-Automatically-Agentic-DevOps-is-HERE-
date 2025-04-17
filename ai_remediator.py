import os
import json
import requests
from dotenv import load_dotenv
import subprocess
import re

load_dotenv()

HUGGINGFACE_API_KEY = os.getenv('HUGGINGFACE_API_KEY')
HUGGINGFACE_MODEL = os.getenv('HUGGINGFACE_MODEL', 'deepseek/deepseek-v3-0324')
HUGGINGFACE_API_URL = os.getenv('HUGGINGFACE_API_URL', 'https://router.huggingface.co/novita/v3/openai/chat/completions')
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
SLACK_WEBHOOK_URL = os.getenv('SLACK_WEBHOOK_URL')
REPO_PATH = os.getenv('REPO_PATH', '.')

def analyze_test_failure(log_content):
    """Analyze test failure using HuggingFace API"""
    headers = {
        "Authorization": f"Bearer {HUGGINGFACE_API_KEY}",
        "Content-Type": "application/json"
    }
    
    prompt = f"""
    Analyze this test failure log and suggest fixes:
    {log_content}
    
    Focus on:
    1. Test assertion mismatches
    2. Incorrect expected values
    3. Simple syntax errors
    
    Return the fix in JSON format with:
    - file_path: path to the file needing changes
    - line_number: line number of the issue
    - current_code: the problematic code
    - fixed_code: the corrected code
    - explanation: brief explanation of the fix
    """
    
    data = {
        "model": HUGGINGFACE_MODEL,
        "messages": [
            {"role": "system", "content": "You are a helpful AI assistant that fixes test failures."},
            {"role": "user", "content": prompt}
        ]
    }
    
    response = requests.post(
        HUGGINGFACE_API_URL,
        headers=headers,
        json=data
    )
    
    try:
        return response.json()['choices'][0]['message']['content']
    except:
        return None

def apply_fix(fix_data):
    """Apply the suggested fix to the code"""
    try:
        fix_data = json.loads(fix_data)
        file_path = fix_data['file_path']
        line_number = fix_data['line_number']
        fixed_code = fix_data['fixed_code']
        
        # Read the file
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        # Replace the problematic line
        lines[line_number - 1] = fixed_code + '\n'
        
        # Write back to file
        with open(file_path, 'w') as f:
            f.writelines(lines)
        
        return True
    except Exception as e:
        print(f"Error applying fix: {str(e)}")
        return False

def commit_and_push_changes(fix_data):
    """Commit and push the changes to GitHub"""
    try:
        fix_data = json.loads(fix_data)
        commit_message = f"🤖 Auto-fix: {fix_data['explanation']}"
        
        # Configure git
        subprocess.run(['git', 'config', '--global', 'user.email', 'ai-remediator@example.com'], cwd=REPO_PATH)
        subprocess.run(['git', 'config', '--global', 'user.name', 'AI Remediator'], cwd=REPO_PATH)
        
        # Add, commit and push
        subprocess.run(['git', 'add', fix_data['file_path']], cwd=REPO_PATH)
        subprocess.run(['git', 'commit', '-m', commit_message], cwd=REPO_PATH)
        subprocess.run(['git', 'push'], cwd=REPO_PATH)
        
        return True
    except Exception as e:
        print(f"Error committing changes: {str(e)}")
        return False

def notify_slack(message, is_error=False):
    """Send notification to Slack"""
    try:
        color = "#ff0000" if is_error else "#36a64f"
        emoji = "❌" if is_error else "🤖"
        
        payload = {
            "text": f"{emoji} *{message}*",
            "attachments": [{
                "color": color,
                "fields": [
                    {
                        "title": "Status",
                        "value": "Error" if is_error else "Success",
                        "short": True
                    }
                ]
            }]
        }
        
        requests.post(SLACK_WEBHOOK_URL, json=payload)
    except Exception as e:
        print(f"Error sending Slack notification: {str(e)}")

def main():
    # Read test failure log
    try:
        with open('test-results.log', 'r') as f:
            log_content = f.read()
        
        # Analyze failure
        fix_data = analyze_test_failure(log_content)
        
        if fix_data:
            # Apply fix
            if apply_fix(fix_data):
                # Commit and push changes
                if commit_and_push_changes(fix_data):
                    notify_slack("Fix applied and pushed successfully!")
                    print("✅ Fix applied and pushed successfully!")
                else:
                    notify_slack("Failed to push changes", is_error=True)
                    print("❌ Failed to push changes")
            else:
                notify_slack("Failed to apply fix", is_error=True)
                print("❌ Failed to apply fix")
        else:
            notify_slack("No fix suggested by AI", is_error=True)
            print("❌ No fix suggested by AI")
    except Exception as e:
        notify_slack(f"Error in AI remediation: {str(e)}", is_error=True)
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    main() 