pipeline {
    agent any
    environment {
        // Optional: set fallback or derived vars
        AGENT_CSV = 'csv/linux_targets.csv'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install Wazuh Agent') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'wazuh_ssh_key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        echo "[INFO] SSH User: $SSH_USER"
                        echo "[INFO] SSH Key Path: $SSH_KEY"
                        chmod 600 "$SSH_KEY"

                        ./scripts/install_agents.sh --csv "$AGENT_CSV" --ssh-key "$SSH_KEY" --ssh-user "$SSH_USER"
                    '''
                }
            }
        }
    }
    post {
        failure {
            echo '[ERROR] Wazuh agent install job failed.'
        }
    }
}
