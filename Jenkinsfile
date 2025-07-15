/*  Jenkinsfile — Wazuh agent roll-out
    Requires:
      • AnsiColor plugin
      • Credentials IDs:
          - ‘jenkins_ssh’  ➜ SSH private-key for Linux targets
          - ‘jenkins_win’ ➜ user / password for WinRM targets
      • Two static agents:
          - linux-agent-01 (also controller of pipeline)
          - windows-agent-01
      • Repo layout:
          csv/linux_targets.csv, csv/windows_targets.csv
          scripts/enroll_linux_agent.sh, scripts/enroll_windows_agent.ps1
*/

pipeline {
    agent { label 'linux-agent-01' }      /* orchestrator node */

    /* keep only PIPELINE options here */
    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        MANAGER_FQDN = 'enroll.cyberhongo.com'
        PORT         = '5443'
        SSH_KEY_ID   = 'jenkins_ssh'
        WIN_CRED_ID  = 'jenkins_win'
    }

    stages {

        /* ──────────────────────────────────────────── */
        stage('Checkout repo') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    checkout scm
                }
            }
        }

        /* ──────────────────────────────────────────── */
        stage('Linux wave') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_ID,
                                                       keyFileVariable: 'SSH_KEY',
                                                       usernameVariable: 'SSH_USER')]) {
                        sh '''
                            echo ":: Rolling out to Linux fleet ::"
                            while IFS=',' read -r IP HOST USER GROUP EXTRA; do
                                [[ "$IP" =~ ^#|^$ ]] && continue   # skip comments / blanks
                                echo "➜  $HOST ($IP) …"

                                # Copy & execute installer
                                scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
                                    scripts/enroll_linux_agent.sh ${USER:-$SSH_USER}@$IP:/tmp/

                                ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" \
                                    ${USER:-$SSH_USER}@$IP \
                                    "sudo bash /tmp/enroll_linux_agent.sh \
                                         -m $MANAGER_FQDN -p $PORT -g $GROUP"
                            done < csv/linux_targets.csv
                        '''
                    }
                }
            }
        }

        /* ──────────────────────────────────────────── */
        stage('Windows wave') {
            agent { label 'windows-agent-01' }     /* switch node */

            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    withCredentials([usernamePassword(credentialsId: env.WIN_CRED_ID,
                                                      usernameVariable: 'WIN_USER',
                                                      passwordVariable: 'WIN_PASS')]) {
                        powershell '''
                            Write-Host ":: Rolling out to Windows fleet ::"
                            Import-Module PSDesiredStateConfiguration      # ensure CIM/WinRM support

                            # Read CSV
                            (Get-Content csv\\windows_targets.csv) | ForEach-Object {
                                if ($_ -match '^(#|$)') { return }          # skip comments / blank
                                $parts  = ($_ -split ',')
                                $ip     = $parts[0]; $host=$parts[1]; $user=$parts[2]; $group=$parts[3]

                                Write-Host "➜  $host ($ip) …"

                                $sess = New-PSSession -ComputerName $ip `
                                                       -Credential (New-Object PSCredential($user,(ConvertTo-SecureString $env:WIN_PASS -AsPlainText -Force))) `
                                                       -Authentication Negotiate

                                Copy-Item scripts\\enroll_windows_agent.ps1 -ToSession $sess -Destination "C:\\Temp\\enroll_windows_agent.ps1" -Force

                                Invoke-Command -Session $sess -ScriptBlock {
                                    param($mgr,$port,$grp)
                                    C:\\Temp\\enroll_windows_agent.ps1 `
                                        -ManagerFqdn $mgr -Port $port -Group $grp
                                } -ArgumentList $env:MANAGER_FQDN,$env:PORT,$group

                                Remove-PSSession $sess
                            }
                        '''
                    }
                }
            }
        }
    }

    /* ──────────────────────────────────────────── */
    post {
        always {
            wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                echo 'Pipeline finished (success, unstable, or failure).'
            }
        }
    }
}
