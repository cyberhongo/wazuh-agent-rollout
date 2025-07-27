pipeline {
  agent any

  environment {
    DEFAULT_PASS = credentials('DEFAULT_PASS') // Set this via Jenkins credentials
    CSV_PATH = "csv/linux_targets.csv"
    DEPLOY_SCRIPT = "scripts/install_agents.sh"
    LOG_PATH = "logs/install.log"
    // We no longer inject SSH_PRIVATE_KEY_PATH here
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Wazuh Agent') {
      steps {
        sh '''
          echo "[INFO] Starting Wazuh agent install job..."

          # Confirm CSV file exists
          if [ ! -f "${CSV_PATH}" ]; then
            echo "[ERROR] CSV file not found: ${CSV_PATH}"
            exit 1
          fi

          # Optional: fallback key path
          KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa.pub}"

          if [ ! -f "$KEY_PATH" ]; then
            echo "[ERROR] SSH public key not found: $KEY_PATH"
            exit 1
          fi

          chmod +x ${DEPLOY_SCRIPT}
          ${DEPLOY_SCRIPT} --csv ${CSV_PATH} --password ${DEFAULT_PASS} --pubkey ${KEY_PATH} | tee ${LOG_PATH}
        '''
      }
    }
  }

  post {
    failure {
      echo "[ERROR] Wazuh agent install job failed."
    }
    success {
      echo "[SUCCESS] Wazuh agent install job completed successfully."
    }
  }
}
