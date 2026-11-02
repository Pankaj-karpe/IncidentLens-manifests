# Usage: powershell -ExecutionPolicy Bypass -File scripts/seal-key.ps1 -Key LLM_API_KEY
param(
  [Parameter(Mandatory)][string]$Key,
  [string]$Name = "incidentlens-worker-secrets",
  [string]$Namespace = "incidentlens-dev"
)
$sec = Read-Host "Value for $Key (typing is hidden)" -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
$tmp = [IO.Path]::GetTempFileName()
try {
  [IO.File]::WriteAllText($tmp, $plain)        # no newline, no BOM
  $enc = kubeseal --raw --from-file=$tmp --name $Name --namespace $Namespace --controller-name sealed-secrets-controller --controller-namespace kube-system
  if ($LASTEXITCODE -ne 0) { throw "kubeseal failed (is the controller running?)" }
} finally { Remove-Item $tmp -Force }
"    ${Key}: $enc"       # paste this line under "encryptedData:" of the worker secret