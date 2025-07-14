/*  Jenkinsfile – Wazuh agent (re)deployment  */

pipeline {
    /* Let each stage pick its own node */
    agent none

    environment {
        MANAGER_FQDN = 'enroll.cyberhongo.com'
        PORT         = '5443'

        /* Jenkins credential IDs you created earlier */
        SSH_KEY_ID   = 'jenkins_ssh'     // private key for Linux targets
        WIN_CRED_ID  = 'jenkins_win'     // WinRM user / password
    }

    options {
        timestamps()
        ansiColor('xterm')
    }

    stages {

        /* ---------- common code checkout (on the linux worker) ---------- */
        stage('Checkout repo') {
            agent { label 'linux-agent-01' }
            steps {
                checkout scm                  // brings in scripts + CSVs
            }
        }

        /* ---------- Linux fleet ---------- */
        stage('Linux wave') {
            agent { label 'linux-agent-01' }

            steps {
                withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_ID,
                                                  keyFileVariable: 'SSH_KEY',
                                                  usernameVariable: 'SSH_USER')]) {

                    sh '''
                      set -euo pipefail
                      while IFS=, read -r IP HOST USER GROUP; do
                          [[ -z "$IP" || "$IP" =~ ^# ]] && continue
                          echo "### Linux target: $HOST ($IP) ###"

                          # Copy script
                          scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
                              enroll_linux_agent.sh ${USER:-$SSH_USER}@"$IP":/tmp/

                          # Execute remotely: remove if present, then run script
                          ssh -tt -o StrictHostKeyChecking=no -i "$SSH_KEY" \
                              ${USER:-$SSH_USER}@"$IP" <<'EOF'
                                sudo systemctl stop wazuh-agent 2>/dev/null || true
                                sudo apt-get -y purge wazuh-agent 2>/dev/null || true
                                bash /tmp/enroll_linux_agent.sh -g '"$GROUP"' \
                                      -m '"$MANAGER_FQDN"' -p '"$PORT"'
                                sudo systemctl enable wazuh-agent
                                sudo systemctl start  wazuh-agent
                              EOF
                      done < linux_targets.csv
                    '''
                }
            }
        }

        /* ---------- Windows fleet ---------- */
        stage('Windows wave') {
            /* This stage actually *runs* on the Windows Jenkins agent */
            agent { label 'windows-agent-01' }

            steps {
                withCredentials([usernamePassword(credentialsId: env.WIN_CRED_ID,
                                                  usernameVariable: 'WIN_USER',
                                                  passwordVariable: 'WIN_PASS')]) {

                    powershell '''
                      Import-Module PSReadLine                # just for colour

                      $SecurePass = ConvertTo-SecureString $Env:WIN_PASS -AsPlainText -Force
                      $Cred       = New-Object System.Management.Automation.PSCredential ($Env:WIN_USER,$SecurePass)

                      Get-Content -Path windows_targets.csv | ForEach-Object {
                          $line = ($_ -split ',')
                          if ($line[0] -and -not ($line[0] -match '^#')) {

                              $IP,$Host,$User,$Group = $line
                              Write-Host "### Windows target: $Host ($IP) ###"

                              # Copy script
                              Copy-Item -Path enroll_windows_agent.ps1 -Destination "\\$IP\\C$\\Temp" -Force

                              # Invoke remote: stop/purge if exists, then enrol
                              Invoke-Command -ComputerName $IP -Credential $Cred -ScriptBlock {
                                  param($Group,$Mgr,$Port)

                                  # Uninstall existing agent if present
                                  if (Get-Service -Name WazuhSvc -ErrorAction SilentlyContinue) {
                                      Stop-Service WazuhSvc -Force
                                      $msi = Get-WmiObject Win32_Product | Where-Object { $_.Name -like 'Wazuh Agent*' }
                                      if ($msi) { $msi.Uninstall() | Out-Null }
                                  }

                                  # Run fresh enrolment
                                  C:\\Temp\\enroll_windows_agent.ps1 `
                                        -Group $Group -ManagerFQDN $Mgr -Port $Port
                              } -ArgumentList $Group,$Env:MANAGER_FQDN,$Env:PORT
                          }
                      }
                    '''
                }
            }
        }
    }  /* stages */

    /* optional reporting / cleanup */
    post {
        always { echo 'Wazuh deployment pipeline finished.' }
    }
}
