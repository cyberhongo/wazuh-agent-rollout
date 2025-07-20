pipeline {
    agent { label 'linux-agent-01' }

    environment {
        TARGET_CSV = "csv/linux_targets.csv"
    }

    options {
        ansiColor('xterm')
        timestamps()
    }

    stages {
        stage('Checkout repo') {
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

        stage('Linux wave') {
            steps {
                withCredentials([
                    file(credentialsId: 'jenkins_ssh_file_key', variable: 'SSH_KEY')
                ]) {
                    sh '''
                        echo -e "\\n\\033[36m[*] Starting Linux agent rollout wave...\\033[0m"
                        chmod +x scripts/run_linux_wave.sh
                        ./scripts/run_linux_wave.sh "$TARGET_CSV" "$SSH_KEY"
                    '''
                }
            }
        }

                stage('Windows wave') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'jenkins_winrm_creds', usernameVariable: 'WIN_USER', passwordVariable: 'WIN_PASS')
                ]) {
                    powershell '''
                        Write-Host "`n[*] Running Windows rollout stage..." -ForegroundColor Cyan
                        .\\scripts\\run_windows_wave.ps1 -CsvPath csv\\windows_targets.csv -CredID jenkins_winrm_creds
                    '''
                }
            }
        }

        stage('Post-report') {
            steps {
                echo "[+] Linux rollout completed."
                archiveArtifacts artifacts: 'linux_wave_*.log', fingerprint: true
            }
        }
    }

    post {
        failure {
            echo "❌ Rollout failed. Check logs for details."
        }
        success {
            echo "✅ All agents enrolled successfully."
        }
    }
}
