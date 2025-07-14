param(
  [String]$Group      = 'lucid-wins',
  [String]$ManagerFQDN= 'enroll.cyberhongo.com',
  [Int]   $Port       = 5443
)
$ErrorActionPreference = 'Stop'

Write-Host "[*] Checking for existing agent…" 
$agent = Get-WmiObject -Class Win32_Product | ? {$_.Name -match "Wazuh*Agent"}
if ($agent) {
    Write-Host "    → uninstalling $($agent.Name)"
    msiexec.exe /x $agent.IdentifyingNumber /qn
    Remove-Item -Recurse -Force 'C:\Program Files (x86)\ossec-agent' -ErrorAction SilentlyContinue
}

Write-Host "[*] Downloading fresh agent…"
$tmp = "$env:TEMP\wazuh-agent.msi"
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi -OutFile $tmp

Write-Host "[*] Installing & registering…"
$msiArgs = @(
 '/i', $tmp, '/qn',
 "WAZUH_MANAGER=$ManagerFQDN",
 "WAZUH_MANAGER_PORT=$Port",
 "WAZUH_AGENT_GROUP=$Group",
 "WAZUH_REGISTRATION_SERVER=$ManagerFQDN"
)
Start-Process msiexec.exe -ArgumentList $msiArgs -Wait

Write-Host "[*] Starting service…"
Start-Service WazuhSvc
Write-Host "[✓] $env:COMPUTERNAME enrolled."
