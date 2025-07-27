pipeline {
  agent any

  environment {
    CSV_PATH = 'csv/linux_targets.csv'
  }

  stages {
    stage('Install Wazuh Agent') {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'jenkins_ssh_file_key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          string(credentialsId: 'DEFAULT_PASS', variable: 'DEFAULT_PASS')
        ]) {
          sh '''
            echo "[INFO] Using SSH User: $SSH_USER"
            echo "[INFO] Using SSH Key at: $SSH_KEY"
            chmod 600 "$SSH_KEY"

            echo "[INFO] Deploying and installing Wazuh agent on Linux targets..."
            ./scripts/install_agents.sh \
              --csv "$CSV_PATH" \
              --ssh-key "$SSH_KEY" \
              --ssh-user "$SSH_USER" \
              --password "$DEFAULT_PASS"
          '''
        }
      }
    }
  }
}
