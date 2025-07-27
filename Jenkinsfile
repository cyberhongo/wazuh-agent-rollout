pipeline {
  agent any

  environment {
    CSV_PATH     = 'csv/linux_targets.csv'
    DEPLOY_SCRIPT = 'scripts/install_agents.sh'
    LOG_PATH     = 'install.log'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Wazuh Agent') {
      environment {
        PUBKEY_PATH = "${WORKSPACE}/id_rsa.pub"
      }
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'jenkins_ssh_key',
                            keyFileVariable: 'SSH_KEY_FILE',
                            usernameVariable: 'SSH_USER'),
          string(credentialsId: 'wazuh_default_pass', variable: 'DEFAULT_PASS')
        ]) {
          sh '''
            echo "[INFO] Starting Wazuh agent install job..."

            echo "[INFO] Generating public key from injected private key..."
            ssh-keygen -y -f "$SSH_KEY_FILE" > "$PUBKEY_PATH"
            chmod 644 "$PUBKEY_PATH"

            echo "[INFO] Launching rollout script with injected key..."
            chmod +x ${DEPLOY_SCRIPT}
            ${DEPLOY_SCRIPT} --csv ${CSV_PATH} --password "${DEFAULT_PASS}" --pubkey "$PUBKEY_PATH" | tee ${LOG_PATH}
          '''
        }
      }
    }
  }

  post {
    failure {
      echo '[ERROR] Wazuh agent install job failed.'
    }
    success {
      echo '[INFO] Wazuh agent rollout completed successfully.'
    }
  }
}
