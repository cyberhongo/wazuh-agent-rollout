/*
 *  Jenkinsfile – LucidSecOps Wazuh Agent Rollout Pipeline
 */
pipeline {
    agent { label 'linux-agent-01' }

    options { timestamps() }

    environment {
        MANAGER_FQDN = 'enroll.cyberhongo.com'
        PORT_DATA    = '1514'
        PORT_AUTH    = '1515'

        SSH_KEY_ID   = 'jenkins_ssh_key' // File credential (private key)
        SSH_USER_ID  = 'jenkins_ssh_user' // Username credential (optional fallback)
        WIN_CRED_ID  = 'jenkins_win' // Windows user/pass
    }

    stages {

        /* ───────────────────────────────────────────── */
        stage('Checkout repo') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    checkout scm
                }
            }
        }

        /* ───────────────────────────────────────────── */
        stage('Linux wave') {
            steps {
                withCredentials([
                    file(credentialsId: env.SSH_KEY_ID, variable: 'SSH_KEY'),
                    usernamePassword(credentialsId: env.SSH_USER_ID,
                                     usernameVariable: 'SSH_USER',
                                     passwordVariable: 'SSH_PASS') // Unused here, but helpful contextually
                ]) {
                    sh '''
                        echo -e "\\n\\033[34m:: Starting Linux Wazuh agent rollout ::\\033[0m\\n"
                        chmod +x scripts/run_linux_wave.sh
                        scripts/run_linux_wave.sh csv/linux_targets.csv "$SSH_KEY"
                    '''
                }
            }
        }

        /* ───────────────────────────────────────────── */
        stage('Windows wave') {
            agent { label 'windows-agent-01' }

            steps {
                withCredentials([
                    usernamePassword(credentialsId: env.WIN_CRED_ID,
                                     usernameVariable: 'WIN_USER',
                                     passwordVariable: 'WIN_PASS')
                ]) {
                    powershell '''
$opts = New-PSSessionOption -SkipCACheck -SkipCNCheck -OperationTimeout 600000
Write-Host "`n:: Rolling out to Windows fleet ::`n" -ForegroundColor Cyan

Import-Csv -Path csv\\windows_targets.csv | ForEach-Object {
    $ip    = $_.IP
    $host  = $_.HOST
    $user  = $_.USER; if (-not $user) { $user = $env:WIN_USER }
    $group = $_.GROUP

    Write-Host ("➜  {0} ({1}) as {2}" -f $host, $ip, $user)

    # Copy the enrollment script
    Copy-Item scripts\\enroll_windows_agent.ps1 `
              -Destination "\\\\$ip\\C$\\Temp" -Force

    $cred = New-Object PSCredential($user,
            (ConvertTo-SecureString $env:WIN_PASS -AsPlainText -Force))

    Invoke-Command -ComputerName $ip -Port 5986 -UseSSL `
                   -SessionOption $opts -Authentication Basic `
                   -Credential $cred `
                   -FilePath   "C:\\Temp\\enroll_windows_agent.ps1" `
                   -ArgumentList "-Group $group",
                                 "-ManagerFQDN $env:MANAGER_FQDN",
                                 "-Port $env:PORT_AUTH"
}
'''
                }
            }
        }

    } // stages

    /* ───────────────────────────────────────────── */
    post {
        always {
            wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                echo 'Pipeline finished.'
            }
        }
    }
}
