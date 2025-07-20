pipeline {
    agent any

    environment {
        SSH_USER = credentials('ssh_user')        // Injected via Jenkins Credentials
        PRIVKEY   = credentials('ssh_privkey')    // SSH private key for Linux hosts
        WIN_USER  = credentials('win_user')       // Windows admin username
        WIN_PASS  = credentials('win_pass')       // Windows password
    }

    stages {
        stage('Checkout repo') {
            steps {
                checkout scm
            }
        }

        stage('Pre-check CSV Format') {
            steps {
                echo '🔎 Validating Linux and Windows CSV formats...'
                sh 'chmod +x scripts/validate_csv_format.sh'
                sh 'scripts/validate_csv_format.sh csv/linux_targets.csv'
                sh 'scripts/validate_csv_format.sh csv/windows_targets.csv'
            }
        }

        stage('Linux wave') {
            steps {
                script {
                    def linuxTargets = readCSV(file: 'csv/linux_targets.csv')
                    for (row in linuxTargets) {
                        def host = row.hostname
                        def ip   = row.ip
                        echo "🚀 Deploying Wazuh agent to ${host} (${ip})..."

                        def result = sh(
                            script: """
                            ssh -i ${PRIVKEY} -o StrictHostKeyChecking=no ${SSH_USER}@${ip} <<'EOF'
                            echo '[*] Starting Wazuh agent enrollment ::'
                            sudo -S systemctl stop wazuh-agent.service || true
                            sudo -S apt-get remove --purge wazuh-agent -y || true
                            wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.12.0-1_amd64.deb
                            sudo -S dpkg -i wazuh-agent_4.12.0-1_amd64.deb
                            sudo -S bash -c "sed -i 's/<address>.*<\\/address>/<address>enroll.cyberhongo.com<\\/address>/' /var/ossec/etc/ossec.conf"
                            sudo -S systemctl enable wazuh-agent
                            sudo -S systemctl start wazuh-agent
                            EOF
                            """,
                            returnStatus: true
                        )

                        if (result != 0) {
                            error "❌ Linux deployment failed for ${host} (${ip})"
                        }
                    }
                }
            }
        }

        stage('Windows wave') {
            steps {
                script {
                    def windowsTargets = readCSV(file: 'csv/windows_targets.csv')
                    for (row in windowsTargets) {
                        def host = row.hostname
                        def ip   = row.ip
                        echo "🚀 Deploying Wazuh agent to Windows host: ${host} (${ip})..."

                        def result = powershell(
                            script: """
                            \$secpasswd = ConvertTo-SecureString '${WIN_PASS}' -AsPlainText -Force
                            \$cred = New-Object System.Management.Automation.PSCredential('${WIN_USER}', \$secpasswd)
                            Invoke-Command -ComputerName ${ip} -Credential \$cred -ScriptBlock {
                                Write-Output 'Starting Wazuh install...'
                                # Placeholder: Copy installer + run install steps
                            }
                            """,
                            returnStatus: true
                        )

                        if (result != 0) {
                            error "❌ Windows deployment failed for ${host} (${ip})"
                        }
                    }
                }
            }
        }

        stage('Git commit & push rollout log') {
            when {
                expression { return fileExists('rollout_logs/') }
            }
            steps {
                script {
                    sh '''
                    git config user.name "LucidMatrixBot"
                    git config user.email "automation@cyberhongo.com"
                    git add rollout_logs/*
                    git commit -m "📝 Add rollout logs $(date +%Y-%m-%dT%H:%M:%S)"
                    git push origin main
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully.'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for details.'
        }
    }
}

// Helper function for reading CSV files
def readCSV(Map args) {
    def rows = []
    def file = args.file
    def content = readFile(file).split('\n')
    def headers = content[0].split(',')
    content.drop(1).each { line ->
        def values = line.split(',')
        def row = [:]
        headers.eachWithIndex { h, i -> row[h.trim()] = values[i]?.trim() }
        rows << row
    }
    return rows
}
