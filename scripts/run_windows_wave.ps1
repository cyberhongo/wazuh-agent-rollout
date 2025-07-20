param (
    [string]$CsvPath,
    [string]$CredID,
    [int]$MaxRetries = 3
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "windows_wave_$timestamp.log"

function Log {
    param([string]$message)
    $logEntry = "$(Get-Date -Format "u") $message"
    $logEntry | Tee-Object -Append -FilePath $logFile
}

Log "`n:: Starting Windows Wazuh agent rollout wave ::"

$targets = Import-Csv -Path $CsvPath | Where-Object { $_.HOSTNAME -and $_.IP }

foreach ($target in $targets) {
    $hostname = $target.HOSTNAME
    $ip = $target.IP
    $user = if ($target.USER) { $target.USER } else { "Administrator" }
    $group = if ($target.GROUP) { $target.GROUP } else { "lucid-windows" }

    Log "`n➜ Target: $hostname ($ip) as $user"

    $attempt = 1
    $success = $false

    while ($attempt -le $MaxRetries -and -not $success) {
        Log "[*] Attempt $attempt of $MaxRetries"
        try {
            Invoke-Command -ComputerName $ip -Credential (Get-Credential $CredID) -ScriptBlock {
                param($hostname, $group)
                Write-Host ">>> [$hostname] Downloading agent..."
                Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi" `
                    -OutFile "C:\\Windows\\Temp\\wazuh-agent.msi"

                Write-Host ">>> [$hostname] Installing agent..."
                Start-Process "msiexec.exe" -ArgumentList "/i C:\\Windows\\Temp\\wazuh-agent.msi /quiet" -Wait

                Write-Host ">>> [$hostname] Configuring ossec.conf..."
                $confPath = "C:\\Program Files (x86)\\ossec-agent\\ossec.conf"
                (Get-Content $confPath) -replace "<address>.*?</address>", "<address>enroll.cyberhongo.com</address>" |
                    Set-Content $confPath

                Write-Host ">>> [$hostname] Registering with manager..."
                Start-Process "C:\\Program Files (x86)\\ossec-agent\\agent-auth.exe" `
                    -ArgumentList "-m enroll.cyberhongo.com -A $hostname -G $group" -Wait

                Write-Host ">>> [$hostname] Starting agent..."
                Start-Service -Name "WazuhSvc"

                Write-Host "✔ [$hostname] Enrollment complete."
            } -ArgumentList $hostname, $group -ErrorAction Stop

            Log "✔ Success: $hostname enrolled successfully."
            $success = $true
        }
        catch {
            Log "❌ Error on $hostname (attempt $attempt): $_"
            Start-Sleep -Seconds 10
            $attempt++
        }
    }

    if (-not $success) {
        Log "⛔ FAILED: $hostname could not be enrolled after $MaxRetries attempts."
    }
}

Log "`n:: Windows rollout wave complete ::"
