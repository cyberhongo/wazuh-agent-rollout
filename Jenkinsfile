pipeline {
    agent any

    environment {
        // Ensure consistent path to sshpass
        PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin"
    }

    options {
        ansiColor('xterm')
        timestamps()
    }

    parameters {
        string(name: 'CSV_FILE', defaultValue: 'csv/linux_targets.csv', description: 'Target CSV file')
    }

    stages {

        stage('Checkout Code') {
            steps {
                git credentialsId: 'jenkins_git', url: 'https://github.com/cyberhongo/wazuh-agent-rollout'
            }
        }

        stage('Install Wazuh Agent') {
            environment {
                SSH_USER = 'robot'
            }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ssh_key', keyFileVariable: 'SSH_KEY'),
                    usernamePassword(credentialsId: 'default_password', usernameVariable: 'UNUSED', passwordVariable: 'DEFAULT_PASS')
                ]) {
                    sh '''
                        echo "[INFO] Using SSH User: $SSH_USER"
                        echo "[INFO] Using SSH Key at: $SSH_KEY"
                        chmod 600 "$SSH_KEY"

                        echo "[INFO] Checking for sshpass..."
                        if ! command -v sshpass >/dev/null 2>&1 && [ -x /usr/bin/sshpass ]; then
                            echo "[WARN] sshpass not in PATH. Manually setting path to /usr/bin/sshpass"
                            alias sshpass='/usr/bin/sshpass'
                        elif ! command -v sshpass >/dev/null 2>&1; then
                            echo "[ERROR] sshpass not found. Aborting."
                            exit 1
                        fi

                        echo "[INFO] Deploying and installing Wazuh agent on Linux targets..."
                        ./scripts/install_agents.sh --csv ${CSV_FILE} --ssh-key "$SSH_KEY" --ssh-user "$SSH_USER" --password "$DEFAULT_PASS"
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "[ERROR] Pipeline failed. Check the logs above for details."
        }
    }
}
