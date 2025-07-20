# install_wazuh_agent.ps1
# ========================
# Production-ready installation script for Wazuh Agent on Windows

$AgentManager = "wazuh.cyberhongo.com"
$GroupName = "win_agents"
$EnrollmentUser = "enroll"
$EnrollmentPassword = "ENROLL_SECRET"  # 🔐 REPLACE or pass as parameter securely

$InstallerURL = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.8.0-1.msi"
$InstallerPath = "$env:TEMP\wazuh-agent.msi"

Write-Output "📦 Downloading Wazuh Agent..."
Invoke-WebRequest -Uri $InstallerURL -OutFile $InstallerPath

Write-Output "🛠 Installing Wazuh Agent..."
Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" /quiet" -Wait

# Configure agent
Write-Output "⚙ Configuring agent..."
& "$Env:ProgramFiles\ossec-agent\agent-auth.exe" -m $AgentManager -A $env:COMPUTERNAME -G $GroupName -u $EnrollmentUser -p $EnrollmentPassword

Write-Output "🚀 Starting agent..."
Start-Service WazuhSvc

Write-Output "✅ Wazuh Agent installed and running."
