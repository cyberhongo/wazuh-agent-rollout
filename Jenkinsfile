/*
 *  Jenkinsfile – LucidSecOps Wazuh agent rollout
 *  - Works with one Linux controller/worker (label: linux-agent-01)
 *    and one Windows worker  (label: windows-agent-01)
 *  - Reads clean CSVs from repo/csv/
 *  - Uses ssh key + WinRM creds stored in Jenkins credentials store
 */

pipeline {
    /* master/“controller” runs nothing → pick dedicated Linux node */
    agent { label 'linux-agent-01' }

    options {
        timestamps()
    }

    environment {
        /* Wazuh enrollment */
        MANAGER_FQDN = 'enroll.cyberhongo.com'
        PORT_DATA    = '1514'   // manager-to-agent data
        PORT_AUTH    = '1515'   // agent-auth enrollment

        /* Jenkins credential IDs */
        SSH_KEY_ID  = 'jenkins_ssh'   // SSH User + private-key cred
        WIN_CRED_ID = 'jenkins_win'   // Username & password cred
    }

    stages {

        /* ──────────────────────────── */
        stage('Checkout repo') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    checkout scm
                }
            }
        }

        /* ──────────────────────────── */
        stage('Linux wave') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: env.SSH_KEY_ID,
                                      keyFileVariable: 'SSH_KEY',
                                      usernameVariable: 'SSH_USER')
                ]) {

                    /*
                     *  Run the loop explicitly with /bin/bash
                     *  – skips blank / comment lines
                     */
                    sh(script: '''
#!/usr/bin/env bash
set -euo pipefail

echo -e "\\n\\e[34m:: Rolling out to Linux fleet ::\\e[0m"

while IFS=',' read -r IP HOST USER GROUP _; do
  # Skip empty rows or rows whose first non-blank char is '#'
  [[ -z "${IP// }" || "${IP}" == \#* ]] && continue

  USER=${USER:-robot}

  echo -e "\\e[36m➜  ${HOST:-$IP} ($IP) as $USER\\e[0m"
  scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
      scripts/enroll_linux_agent.sh "${USER}@${IP}:/tmp/"

  ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" \
      "${USER}@${IP}" \
      "bash /tmp/enroll_linux_agent.sh -g ${GROUP}"
done < csv/linux_targets.csv
''', shell: '/bin/bash')
                }
            }
        }

        /* ──────────────────────────── */
        stage('Windows wave') {
            /* run only on Windows agent */
            agent { label 'windows-agent-01' }

            steps {
                withCredentials([
                    usernamePassword(credentialsId: env.WIN_CRED_ID,
                                     usernameVariable: 'WIN_USER',
                                     passwordVariable: 'WIN_PASS')
                ]) {
                    powershell '''
#--- Helper: session opts that skip CN / CA checks ----#
$opts = New-PSSessionOption -SkipCACheck -SkipCNCheck `
                            -OperationTimeout 600000

Write-Host "`n:: Rolling out to Windows fleet ::`n" -ForegroundColor Cyan

Get-Content csv\\windows_targets.csv | ForEach-Object {
    $_ = $_.Trim()
    if (-not $_ -or $_ -match '^#') { return }

    $parts = $_ -split ','
    $ip,$host,$user,$group = $parts[0..3]

    if (-not $user) { $user = $env:WIN_USER }  # fallback

    Write-Host "➜  $host ($ip) as $user"
    Copy-Item scripts\\enroll_windows_agent.ps1 `
              -Destination "\\\\$ip\\C$\\Temp\\" -Force

    $cred = New-Object System.Management.Automation.PSCredential `
              ($user, (ConvertTo-SecureString $env:WIN_PASS -AsPlainText -Force))

    Invoke-Command -ComputerName $ip -Port 5986 -UseSSL `
                   -SessionOption $opts -Authentication Basic `
                   -Credential $cred `
                   -FilePath "\\\\$ip\\C$\\Temp\\enroll_windows_agent.ps1" `
                   -ArgumentList "-Group $group",
                                 "-ManagerFQDN $env:MANAGER_FQDN",
                                 "-Port $env:PORT_AUTH"
}
'''
                }
            }
        }
    } /* stages */

    /* ──────────────────────────── */
    post {
        always {
            wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                echo "Pipeline finished (success, unstable, or failure)."
            }
        }
    }
}
