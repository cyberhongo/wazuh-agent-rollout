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
          file(credentialsId: 'wazuh_ssh_key', variable: 'SSH_KEY_FILE'),
          string(credentialsId: 'wazuh_default_pass', variable: 'WAZUH_PASS')
        ]) {
          sh '''
           echo "[INFO] Starting Wazuh agent install job..."
           echo "[INFO] Generating public key from injected private key..."
           ssh-keygen -y -f $SSH_KEY_FILE > id_rsa.pub
           chmod 644 id_rsa.pub

           echo "[INFO] Launching rollout script with injected key..."
           chmod +x scripts/install_agents.sh
           scripts/install_agents.sh \
             --csv csv/linux_targets.csv \
             --authpass $WAZUH_PASS \
             --pubkey $(pwd)/id_rsa.pub | tee install.log
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
