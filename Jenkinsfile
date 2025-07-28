pipeline {
    agent { label 'linux-agent-01' }

    environment {
        SSH_USER = 'robot'
    }

    options {
        ansiColor('xterm')  // Optional: for colorized logs
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/cyberhongo/wazuh-agent-rollout',
                        credentialsId: 'jenkins_git'
                    ]]
                ])
            }
        }

        stage('Validate Dependencies') {
            steps {
                sh '''
                    echo "[INFO] Validating sshpass availability..."
                    if ! command -v sshpass >/dev/null 2>&1; then
                        echo "[ERROR] sshpass is missing on this Jenkins agent."
                        echo "[HINT] Please pre-install it manually on 'linux-agent-01' or bake it into the agent image."
                        exit 127
                    fi
                '''
            }
        }

        stage('Install Wazuh Agents') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ssh_key_robot', keyFileVariable: 'SSH_KEY'),
                    usernamePassword(credentialsId: 'ssh_default_pass', passwordVariable: 'DEFAULT_PASS', usernameVariable: 'UNUSED')
                ]) {
                    sh '''
                        echo "[INFO] Preparing to install agents..."
                        chmod 600 "$SSH_KEY"

                        ./scripts/install_agents.sh \\
                            --csv csv/linux_targets.csv \\
                            --ssh-key "$SSH_KEY" \\
                            --ssh-user "$SSH_USER" \\
                            --password "$DEFAULT_PASS"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "[SUCCESS] Wazuh agents deployed successfully."
        }
        failure {
            echo "[ERROR] Pipeline failed. Review logs above for root cause."
        }
    }
}
