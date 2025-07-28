pipeline {
    agent any

    environment {
        SSH_KEY_PATH = '/home/robot/.ssh/id_rsa'
        SSH_PUB_PATH = '/home/robot/.ssh/id_rsa.pub'
        SSH_USER     = 'robot'
        SSH_PASS     = credentials('wazuh_ssh_pass')
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
    }

    stages {
        stage('Prepare') {
            steps {
                echo "[INFO] Validating CSV structure..."
                sh 'bash scripts/validate_csv_format.sh csv/linux_targets.csv'
            }
        }

        stage('Deploy SSH Keys') {
            steps {
                echo "[INFO] Distributing SSH key to targets..."
                sh 'bash scripts/deploy_ssh_pubkeys.sh --csv csv/linux_targets.csv --ssh-key "$SSH_PUB_PATH" --ssh-user "$SSH_USER" --password "$SSH_PASS"'
            }
        }

        stage('Clean Existing Agents') {
            steps {
                echo "[INFO] Cleaning up existing Wazuh agents..."
                sh 'bash scripts/cleanup_agents.sh --csv csv/linux_targets.csv --ssh-key "$SSH_KEY_PATH" --ssh-user "$SSH_USER"'
            }
        }

        stage('Install Wazuh Agents') {
            steps {
                echo "[INFO] Installing and enrolling Wazuh agents..."
                sh 'bash scripts/install_agents.sh --csv csv/linux_targets.csv --ssh-key "$SSH_KEY_PATH" --ssh-user "$SSH_USER"'
            }
        }
    }

    post {
        always {
            echo "[INFO] Pipeline completed. Check logs above for results."
        }
        failure {
            echo "[ERROR] One or more stages failed. Investigate the errors above."
        }
    }
}
