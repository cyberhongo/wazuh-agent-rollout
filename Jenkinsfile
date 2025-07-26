pipeline {
    agent none

    environment {
        ENV_FILE = '.env'
    }

    stages {
        stage('Initialize') {
            agent { label 'linux-agent-01' }
            steps {
                echo "[+] Initializing environment..."

                // Ensure .env exists
                sh '''
                    if [ ! -f "$ENV_FILE" ]; then
                        echo "[ERROR] Missing .env file"
                        exit 1
                    fi
                '''

                // Load environment variables
                script {
                    def envVars = readFile('.env').split('\n')
                    envVars.each {
                        def kv = it.trim().split('=')
                        if (kv.length == 2) {
                            env[kv[0]] = kv[1]
                        }
                    }
                }
            }
        }

        stage('Clean Linux Agents') {
            agent { label 'linux-agent-01' }
            steps {
                echo "[*] Cleaning Linux agents..."
                sh '''
                    chmod +x scripts/cleanup_agents.sh
                    ./scripts/cleanup_agents.sh csv/linux_targets.csv
                '''
            }
        }

        stage('Clean Windows Agents') {
            agent { label 'windows-agent-01' }
            steps {
                echo "[*] Skipping Windows cleanup - manual for now."
                // Future: call PowerShell cleanup via file share or WinRM
            }
        }

        stage('Install Linux Agents') {
            agent { label 'linux-agent-01' }
            steps {
                echo "[*] Installing Wazuh agents on Linux..."
                sh '''
                    chmod +x scripts/install_agents.sh
                    ./scripts/install_agents.sh csv/linux_targets.csv
                '''
            }
        }

        stage('Enroll Linux Agents') {
            agent { label 'linux-agent-01' }
            steps {
                echo "[*] Enrolling Linux agents..."
                sh '''
                    chmod +x scripts/enroll_linux_agent.sh
                    ./scripts/enroll_linux_agent.sh csv/linux_targets.csv
                '''
            }
        }

        stage('Enroll Windows Agents') {
            agent { label 'windows-agent-01' }
            steps {
                echo "[*] Manual step - run install_wazuh_agent.ps1 from shared folder."
                echo "[*] Example: http://fileserver/install_wazuh_agent.ps1"
            }
        }
    }

    post {
        success {
            echo "[+] Wazuh agent deployment complete!"
        }
        failure {
            echo "[!] Pipeline failed. Check logs above."
        }
    }
}
