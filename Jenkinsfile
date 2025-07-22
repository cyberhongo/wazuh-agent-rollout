// Jenkinsfile for Wazuh Agent Reinstallation and Enrollment (Clean Environment)

pipeline {
    agent any

    environment {
        ENROLLMENT_FQDN = "enroll.cyberhongo.com"
        ENROLLMENT_PORT = "5443"
        LINUX_CSV = "wazuh_agents_linux.csv"
        GROUP_LINUX = "lucid-linux"
        GROUP_NETOPS = "lucid-netops"
        JENKINS_NODE_LABEL = "wazuh-deployer"
    }

    stages {

        stage('Clean Linux Agents') {
            agent { label "${JENKINS_NODE_LABEL}" }
            steps {
                echo "Uninstalling old Wazuh agents from Linux nodes..."
                sh '''
                while IFS=',' read -r hostname ip user group; do
                    echo "Uninstalling Wazuh Agent on $hostname ($ip)..."
                    ssh -o StrictHostKeyChecking=no "$user@$ip" "sudo systemctl stop wazuh-agent; sudo /var/ossec/bin/wazuh-control stop; sudo rm -rf /var/ossec" || true
                done < ${LINUX_CSV}
                '''
            }
        }

        stage('Install and Enroll Linux Agents') {
            agent { label "${JENKINS_NODE_LABEL}" }
            steps {
                echo "Installing fresh Wazuh agents and enrolling via ${ENROLLMENT_FQDN}:${ENROLLMENT_PORT}..."
                sh '''
                while IFS=',' read -r hostname ip user group; do
                    echo "Installing on $hostname ($ip) - Group: $group..."
                    ssh -o StrictHostKeyChecking=no "$user@$ip" "\
                        curl -so wazuh-agent-install.sh https://packages.wazuh.com/4.12/wazuh-agent-4.12.0-linux.sh && \
                        sudo bash wazuh-agent-install.sh --enrollment-ip ${ENROLLMENT_FQDN} --enrollment-port ${ENROLLMENT_PORT} --agent-group $group && \
                        sudo systemctl enable wazuh-agent && \
                        sudo systemctl start wazuh-agent"
                done < ${LINUX_CSV}
                '''
            }
        }

        stage('Verify Agents') {
            agent { label "${JENKINS_NODE_LABEL}" }
            steps {
                echo 'Verifying enrolled agents on the Wazuh manager...'
                sh '/var/ossec/bin/agent_control -lc'
            }
        }
    }

    post {
        failure {
            echo 'Wazuh agent deployment pipeline FAILED.'
        }
        success {
            echo 'All Wazuh agents successfully installed and enrolled.'
        }
    }
}
