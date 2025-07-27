pipeline {
    agent any

    environment {
        DEFAULT_PASS = credentials('default-linux-password')
        PUBKEY_PATH  = credentials('linux-ssh-pubkey')
    }

    stages {

        stage('Deploy SSH Public Keys') {
            steps {
                echo "[INFO] Deploying SSH keys to Linux targets"
                sh '''
                bash scripts/deploy_ssh_pubkeys.sh "$PUBKEY_PATH" "$DEFAULT_PASS"
                '''
            }
        }

        stage('Install Linux Wazuh Agents') {
            steps {
                echo "[INFO] Installing Wazuh agent on all Linux hosts"
                sh 'bash scripts/run_linux_wave.sh'
            }
        }

        stage('Install Windows Wazuh Agents') {
            steps {
                echo "[INFO] Manual run required for Windows hosts. Skipping this stage for now."
            }
        }
    }

    post {
        failure {
            echo "[ERROR] Pipeline failed. Check logs for details."
        }
        success {
            echo "[INFO] SSH deployment and Linux agent install complete."
        }
    }
}
