pipeline {
    agent { label 'linux-agent-01' }  // Jenkins node label

    environment {
        SSH_USER = 'robot'
        SSH_KEY = credentials('ssh_key_robot')
        DEFAULT_PASS = credentials('ssh_default_pass')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM', 
                          branches: [[name: '*/main']], 
                          userRemoteConfigs: [[
                              url: 'https://github.com/cyberhongo/wazuh-agent-rollout',
                              credentialsId: 'jenkins_git']]
                ])
            }
        }

        stage('Validate Dependencies') {
            steps {
                sh '''
                    echo [INFO] Validating sshpass availability...
                    if ! command -v sshpass >/dev/null 2>&1; then
                        echo [ERROR] sshpass is missing on this Jenkins agent.
                        echo [HINT] Please pre-install it manually on 'linux-agent-01' or bake it into the agent image.
                        exit 127
                    else
                        echo [INFO] sshpass is available.
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
                        echo [INFO] Using SSH User: $SSH_USER
                        echo [INFO] Using SSH Key at: $SSH_KEY
                        chmod 600 $SSH_KEY

                        echo [INFO] Deploying and installing Wazuh agent on Linux targets...
                        ./scripts/install_agents.sh \
                            --csv csv/linux_targets.csv \
                            --ssh-key $SSH_KEY \
                            --ssh-user $SSH_USER \
                            --password $DEFAULT_PASS
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "[ERROR] Pipeline failed. Check the logs above for details."
        }
        success {
            echo "[SUCCESS] Wazuh agents deployed successfully."
        }
    }
}
