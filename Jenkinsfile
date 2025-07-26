pipeline {
    agent any

    environment {
        // Load from .env file in root directory
        AGENT_DEB_URL = "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.12.0-1_amd64.deb"
        MANAGER_FQDN = "enroll.cyberhongo.com"
        AGENT_GROUP = "lucid-linux"
    }

    options {
        ansiColor('xterm')
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {

        stage('Validate Linux Targets CSV') {
            steps {
                echo 'Validating linux_targets.csv format...'
                sh 'bash scripts/validate_csv_format.sh csv/linux_targets.csv'
            }
        }

        stage('Clean Linux Agents') {
            steps {
                script {
                    def targets = readCSV(file: 'csv/linux_targets.csv')
                    for (row in targets) {
                        def host = row.hostname
                        def user = row.username ?: 'robot'

                        echo "Cleaning Wazuh agent on ${host} as ${user}..."

                        sh """
                        ssh -o StrictHostKeyChecking=no ${user}@${host} '
                            bash -s' < scripts/cleanup_agents.sh
                        """
                    }
                }
            }
        }

        stage('Install Linux Agents') {
            steps {
                script {
                    def targets = readCSV(file: 'csv/linux_targets.csv')
                    for (row in targets) {
                        def host = row.hostname
                        def user = row.username ?: 'robot'

                        echo "Installing Wazuh agent on ${host} as ${user}..."

                        sh """
                        ssh -o StrictHostKeyChecking=no ${user}@${host} '
                            AGENT_DEB_URL="${AGENT_DEB_URL}" \
                            MANAGER_FQDN="${MANAGER_FQDN}" \
                            AGENT_GROUP="${AGENT_GROUP}" \
                            bash -s' < scripts/install_agents.sh
                        """
                    }
                }
            }
        }
    }

    post {
        failure {
            mail to: 'ops@lucidityconsult.net',
                 subject: "❌ Jenkins Build #${env.BUILD_NUMBER} Failed: Wazuh Agent Deployment",
                 body: "Check the Jenkins job output at ${env.BUILD_URL}"
        }
        success {
            echo "✅ All Wazuh Linux agents enrolled successfully to ${MANAGER_FQDN}."
        }
    }
}

// Helper function to read CSV
def readCSV(Map args) {
    def file = args.file
    def data = []

    if (!file?.trim()) error "CSV file path not provided"

    def csvContent = readFile(file).trim()
    def lines = csvContent.split("\n")

    lines.drop(1).each { line ->
        def parts = line.split(",")
        if (parts.size() >= 2) {
            data << [hostname: parts[0].trim(), username: parts[1].trim()]
        } else {
            error "Invalid CSV line: ${line}"
        }
    }
    return data
}
