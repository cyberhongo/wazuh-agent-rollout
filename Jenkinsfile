pipeline {
    agent any
    environment {
        LINUX_CSV = 'csv/linux_targets.csv'
        WINDOWS_CSV = 'csv/windows_targets.csv'
    }

    stages {
        stage('Checkout repo') {
            steps {
                checkout scm
            }
        }

        stage('Pre-check CSVs') {
            steps {
                echo "\n🔎 Validating Linux and Windows CSV formats..."
                sh 'chmod +x scripts/validate_csv_format.sh'
                sh 'scripts/validate_csv_format.sh ${LINUX_CSV}'
                sh 'scripts/validate_csv_format.sh ${WINDOWS_CSV}'
            }
        }

        stage('Linux wave') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'jenkins_ssh_key',  // Replace with your actual Jenkins SSH credential ID
                    keyFileVariable: 'PRIVKEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    script {
                        def targets = readCSV(file: env.LINUX_CSV)
                        for (line in targets.drop(1)) {
                            def (hostname, ip, user, group) = line
                            echo "🚀 Deploying Wazuh agent to $hostname ($ip)..."
                            sh """
                                ssh -i "$PRIVKEY" -o StrictHostKeyChecking=no "$SSH_USER@$ip" "bash -s" < ./scripts/enroll_linux_agent.sh "$hostname"
                            """
                        }
                    }
                }
            }
        }

        stage('Windows wave') {
            steps {
                echo "⚠️ Windows agent deployment not implemented yet. Add WinRM/PsExec logic here."
            }
        }
    }

    post {
        always {
            echo '✅ Pipeline completed.'
        }
    }
}

def readCSV(Map args = [:]) {
    def file = args.file
    return readFile(file).split('\n').collect { it.trim().split(',').collect { it.trim() } }
}
