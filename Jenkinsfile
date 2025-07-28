pipeline {
    agent { label 'linux-agent-01' }

    environment {
        PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin:/usr/local/bin"
    }

    options {
        ansiColor('xterm')
        timestamps()
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '[INFO] Code already checked out via declarative SCM.'
                sh 'ls -la'
            }
        }

        stage('Install Wazuh Agent') {
            steps {
                sh '''
                    echo "[INFO] Running Wazuh agent installation script..."
                    chmod +x scripts/install_agents.sh
                    ./scripts/install_agents.sh
                '''
            }
        }
    }

    post {
        failure {
            echo '[ERROR] Pipeline failed. Check the logs above for details.'
        }
        success {
            echo '[SUCCESS] Wazuh agent rollout completed successfully.'
        }
    }
}
