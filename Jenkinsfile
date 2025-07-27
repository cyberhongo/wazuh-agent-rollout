pipeline {
  agent any

  environment {
    // This assumes you've added the secret in Jenkins credentials
    // Adjust these IDs or inline values as needed
    DEFAULT_PASS = credentials('DEFAULT_PASS') 
    SSH_KEY_PATH = credentials('SSH_PRIVATE_KEY_PATH')
  }

  stages {
    stage('Install Linux Agents') {
      steps {
        echo "[INFO] Starting Wazuh Agent Install Pipeline"
        sh '''
          echo "[INFO] Current working directory: $(pwd)"
          echo "[INFO] Listing project files:"
          find . -type f

          # Make sure script is executable
          chmod +x scripts/install_agents.sh

          # Run the install script with correct CSV path and env var for password
          scripts/install_agents.sh ./csv/linux_targets.csv "$DEFAULT_PASS"
        '''
      }
    }
  }

  post {
    failure {
      echo '[ERROR] Wazuh agent install job failed.'
    }
    success {
      echo '[SUCCESS] Wazuh agents installed successfully.'
    }
  }
}
