pipeline {
    agent {
        label 'linux-agent-01'
    }

    environment {
        CSV = 'csv/linux_targets.csv'
        SSH_KEY = '/home/jenkins/.ssh/id_rsa.pub'
        SSH_USER = 'robot'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        ansiColor('xterm')
        timestamps()
    }

    stages {
        stage('Validate CSV') {
            steps {
                echo "[INFO] Validating CSV structure..."
                sh 'bash scripts/validate_csv_format.sh ${CSV}'
            }
        }

        stage('Deploy SSH Keys') {
            environment {
                SSH_PASS = credentials('jenkins_ssh_password')
            }
            steps {
                echo "[INFO] Distributing SSH key to targets..."
                sh '''
                    bash scripts/deploy_ssh_pubkeys.sh \
                        --csv ${CSV} \
                        --ssh-key ${SSH_KEY} \
                        --ssh-user ${SSH_USER} \
                        --password ${SSH_PASS}
                '''
            }
        }

        stage('Clean Existing Agents') {
            steps {
                echo "[INFO] Cleaning up existing Wazuh agents..."
                sh '''
                    bash scripts/cleanup_agents.sh \
                        --csv ${CSV} \
                        --ssh-key /home/jenkins/.ssh/id_rsa \
                        --ssh-user ${SSH_USER}
                '''
            }
        }

        stage('Install Wazuh Agents') {
            environment {
                DEFAULT_PASS = credentials('jenkins_ssh_password')
            }
            steps {
                echo "[INFO] Installing and enrolling Wazuh agents..."
                sh '''
                    bash scripts/install_agents.sh \
                        --csv ${CSV} \
                        --ssh-key /home/jenkins/.ssh/id_rsa \
                        --ssh-user ${SSH_USER} \
                        --password ${DEFAULT_PASS}
                '''
            }
        }
    }

    post {
        success {
            echo "[✅] Wazuh agent rollout completed successfully."
        }
        failure {
            echo "[ERROR] One or more stages failed. Investigate the logs above."
        }
    }
}
