pipeline {
    agent any

    environment {
        LINUX_CSV = 'csv/linux_targets.csv'
        WINDOWS_CSV = 'csv/windows_targets.csv'
        SSH_USER = credentials('wazuh_ssh_user')
        PRIVKEY = credentials('wazuh_ssh_privkey')
        WIN_USER = credentials('wazuh_win_user')
        WIN_PASS = credentials('wazuh_win_pass')
    }

    options {
        timestamps()
    }

    stages {
        stage('Checkout repo') {
            steps {
                checkout scm
            }
        }

        stage('Pre-check CSV Format') {
            steps {
                echo "🔎 Validating Linux and Windows CSV formats..."
                sh 'chmod +x scripts/validate_csv_format.sh'
                sh 'scripts/validate_csv_format.sh ${LINUX_CSV}'
                sh 'scripts/validate_csv_format.sh ${WINDOWS_CSV}'
            }
        }

        stage('Linux wave') {
            steps {
                script {
                    def targets = readCSV file: env.LINUX_CSV

                    if (targets.size() == 0) {
                        error "❌ No Linux targets found in CSV. Check format and contents."
                    }

                    targets.each { row ->
                        echo "🚀 Deploying Wazuh agent to ${row.hostname} (${row.ip})..."

                        def deployCmd = """
                        ssh -i '${PRIVKEY}' -o StrictHostKeyChecking=no ${SSH_USER}@${row.ip} \\
                        'bash -s' < scripts/enroll_linux_agent.sh ${row.group} ${row.hostname}
                        """

                        sh deployCmd
                    }
                }
            }
        }

        stage('Windows wave') {
            steps {
                script {
                    def targets = readCSV file: env.WINDOWS_CSV

                    if (targets.size() == 0) {
                        error "❌ No Windows targets found in CSV. Check format and contents."
                    }

                    targets.each { row ->
                        echo "💻 Deploying to Windows Host: ${row.hostname} (${row.ip})"

                        def winrmCmd = """
                        powershell -Command \"
                        \$secpasswd = ConvertTo-SecureString '${WIN_PASS}' -AsPlainText -Force;
                        \$cred = New-Object System.Management.Automation.PSCredential ('${row.username}', \$secpasswd);
                        Invoke-Command -ComputerName ${row.ip} -Credential \$cred -ScriptBlock {
                            Invoke-WebRequest -Uri 'http://fileserver/install_wazuh_agent.ps1' -OutFile 'C:\\\\install_wazuh_agent.ps1';
                            & 'C:\\\\install_wazuh_agent.ps1';
                        }
                        \"
                        """

                        bat(script: winrmCmd)
                    }
                }
            }
        }

        stage('Git commit & push rollout log') {
            steps {
                script {
                    def logFile = "logs/rollout_log_${new Date().format('yyyyMMdd_HHmmss')}.txt"

                    sh """
                    mkdir -p logs
                    echo 'Rollout completed at: ' \$(date) > ${logFile}
                    git add ${logFile}
                    git config user.name 'Jenkins'
                    git config user.email 'jenkins@cyberhongo.com'
                    git commit -m '📦 Add rollout log ${logFile}'
                    git push origin main
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for details.'
        }
    }
}

// Utility method
def readCSV(path) {
    def rows = []
    def csvFile = new File(path)

    if (!csvFile.exists()) {
        error "CSV file not found: ${path}"
    }

    def lines = csvFile.readLines()
    def headers = lines[0].split(',')

    lines.drop(1).each { line ->
        def values = line.split(',')
        def row = [:]
        headers.eachWithIndex { header, idx ->
            row[header.trim()] = values[idx].trim()
        }
        rows << row
    }
    return rows
}
