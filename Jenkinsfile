pipeline {
    agent {
        label 'linux-agent-01'
    }

    environment {
        AGENT_PASS = credentials('agent-default-password')
        SSH_KEY_PATH = "${HOME}/.ssh/id_rsa.pub"
        SSH_USER = "robot"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Prep') {
            steps {
                echo "[INFO] Confirming target CSV and scripts are present..."
                sh 'ls -l csv/linux_targets.csv'
                sh 'ls -l scripts/install_agents.sh'
            }
        }

        stage('Install Linux Agents') {
            steps {
                echo "[INFO] Running Wazuh agent installation script..."
                sh '''
                    chmod +x scripts/install_agents.sh
                    ./scripts/install_agents.sh \
                        --csv csv/linux_targets.csv \
                        --ssh-key ${SSH_KEY_PATH} \
                        --ssh-user ${SSH_USER} \
                        --password "${AGENT_PASS}"
                '''
            }
        }

        stage('Post Check') {
            steps {
                echo "[INFO] Listing active agents..."
                sh 'curl -sk -u wazuh:${AGENT_PASS} https://wazuh.cyberhongo.com:55000/agents | jq .data'
            }
        }
    }

    post {
        failure {
            echo "[ERROR] Jenkins pipeline failed."
        }
        success {
            echo "[INFO] Jenkins pipeline completed successfully."
        }
    }
}
