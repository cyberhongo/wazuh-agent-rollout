pipeline {
    agent any

    environment {
        LINUX_CSV = 'csv/linux_targets.csv'
        WINDOWS_CSV = 'csv/windows_targets.csv'
        LOG_FILE = "rollout_log_$(new Date().format('yyyyMMdd_HHmmss')).txt"
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
                echo '🔎 Validating Linux and Windows CSV formats...'
                sh 'chmod +x scripts/validate_csv_format.sh'
                sh "scripts/validate_csv_format.sh ${env.LINUX_CSV}"
                sh "scripts/validate_csv_format.sh ${env.WINDOWS_CSV}"
            }
        }

        stage('Linux wave') {
            steps {
                script {
                    def targets = readCSV(env.LINUX_CSV)

                    if (targets.size() == 0) {
                        error "❌ No Linux targets found in CSV. Check format and contents."
                    }

                    targets.each { row ->
                        echo "📄 Parsed CSV row -> Hostname: ${row.hostname}, IP: ${row.ip}, User: ${row.username}, Group: ${row.group}"

                        def cmd = """ssh -i "${PRIVKEY}" -o StrictHostKeyChecking=no ${row.username}@${row.ip} 'bash -s' < scripts/enroll_linux_agent.sh ${row.group}"""
                        echo "🚀 Deploying Wazuh agent to ${row.hostname} (${row.ip})..."
                        sh(script: cmd)
                    }
                }
            }
        }

        stage('Windows wave') {
            steps {
                echo '🔧 Windows rollout to be implemented with WinRM / Ansible later...'
                // Placeholder for PowerShell WinRM automation
            }
        }

        stage('Git commit & push rollout log') {
            steps {
                script {
                    sh "git add rollout_logs/${LOG_FILE} || true"
                    sh "git commit -m '📦 Rollout log update: ${LOG_FILE}' || true"
                    sh "git push origin main || true"
                }
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed. Check logs for details.'
        }
    }
}

def readCSV(path) {
    def lines = readFile(path).trim().split('\n')
    def headers = lines[0].split(',').collect { it.trim() }
    def result = []

    for (int i = 1; i < lines.size(); i++) {
        def values = lines[i].split(',').collect { it.trim() }
        def entry = [:]
        for (int j = 0; j < headers.size(); j++) {
            entry[headers[j]] = values[j]
        }
        result << entry
    }
    return result
}
