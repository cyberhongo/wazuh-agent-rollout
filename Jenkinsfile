pipeline {
  agent any

  environment {
    // Injects the Jenkins secret text credential with ID 'default-linux-password'
    DEFAULT_PASS = credentials('default-linux-password')
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {

    stage('Checkout Code') {
      steps {
        git credentialsId: 'jenkins_git', url: 'https://github.com/cyberhongo/wazuh-agent-rollout', branch: 'main'
      }
    }

    stage('Verify CSV Format') {
      steps {
        sh 'bash scripts/validate_csv_format.sh'
      }
    }

    stage('Deploy SSH Keys') {
      steps {
        sh 'bash scripts/deploy_ssh_pubkeys.sh'
      }
    }

    stage('Install Wazuh Agents') {
      steps {
        sh '''
          chmod +x scripts/install_agents.sh
          ./scripts/install_agents.sh
        '''
      }
    }
  }

  post {
    success {
      echo "[SUCCESS] Wazuh agent installation pipeline completed."
    }
    failure {
      echo "[FAILURE] Pipeline failed. Check logs and investigate immediately."
    }
    always {
      echo "[INFO] Wazuh rollout job has finished executing."
    }
  }
}
