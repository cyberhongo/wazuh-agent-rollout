pipeline {
    agent { label 'linux-agent-01' }

    options { timestamps() }

    environment {
        MANAGER_FQDN = 'enroll.cyberhongo.com'
        PORT_DATA    = '1514'
        PORT_AUTH    = '1515'

        SSH_KEY_ID   = 'jenkins_ssh_key'   // SSH user-private-key cred
        WIN_CRED_ID  = 'jenkins_win'       // Windows user/pass cred
    }

    stages {

        /* ─────────── 1. Clone Repo ─────────── */
        stage('Checkout repo') {
            steps {
                wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                    checkout scm
                }
            }
        }

        /* ─────────── 2. Pre-Check CSVs ─────────── */
        stage('Pre-check CSVs') {
            steps {
                sh '''
                    echo -e "\\n🔎 Validating Linux and Windows CSV formats..."
                    chmod +x scripts/validate_csv_format.sh
                    scripts/validate_csv_format.sh csv/linux_targets.csv
                    scripts/validate_csv_format.sh csv/windows_targets.csv
                '''
            }
        }

        /* ─────────── 3. Linux Wave ─────────── */
        stage('Linux wave') {
            steps {
                withCredentials([
                    file(credentialsId: 'jenkins_ssh_key', variable: 'SSH_KEY'),
                    usernamePassword(credentialsId: 'jenkins_ssh_user', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')
                ]) {
                    sh '''
                        echo -e "\\n[*] Starting Linux agent rollout wave..."
                        chmod +x scripts/run_linux_wave.sh
                        ./scripts/run_linux_wave.sh csv/linux_targets.csv "$SSH_KEY"
                    '''
                }
            }
        }

        /* ─────────── 4. Windows Wave ─────────── */
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

    $ip   = $_.IP
    $user = $_.USER  ; if (-not $user) { $user = $env:WIN_USER }
    $group= $_.GROUP

    Write-Host ("➜  {0} ({1}) as {2}" -f $_.HOSTNAME,$ip,$user)

    Copy-Item scripts\\enroll_windows_agent.ps1 `
              -Destination "\\\\$ip\\C$\\Temp" -Force

    $cred = New-Object PSCredential($user,
             (ConvertTo-SecureString $env:WIN_PASS -AsPlainText -Force))

    Invoke-Command -ComputerName $ip -Port 5986 -UseSSL `
                   -SessionOption $opts -Authentication Basic `
                   -Credential $cred `
                   -FilePath   "\\\\$ip\\C$\\Temp\\enroll_windows_agent.ps1" `
                   -ArgumentList "-Group $group",
                                 "-ManagerFQDN $env:MANAGER_FQDN",
                                 "-Port $env:PORT_AUTH"
}
'''
                }
            }
        }

    }

    post {
        always {
            wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                echo 'Pipeline finished.'
            }
        }
    }
}
