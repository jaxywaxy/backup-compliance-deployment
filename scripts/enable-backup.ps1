param(
  [Parameter(Mandatory = $true)]
  [string]$VaultName,

  [Parameter(Mandatory = $true)]
  [string]$VaultResourceGroup,

  [Parameter(Mandatory = $true)]
  [string]$VmName,

  [Parameter(Mandatory = $true)]
  [string]$VmResourceGroup,

  [Parameter(Mandatory = $true)]
  [string]$PolicyName,

  [Parameter(Mandatory = $false)]
  [string]$SubscriptionId = '594e0bd0-2a8d-4419-b281-87869c20fd03'
)

# Set subscription context
Set-AzContext -SubscriptionId $SubscriptionId

Write-Host "Enabling backup for VM: $VmName"
Write-Host "Vault: $VaultName in $VaultResourceGroup"
Write-Host "Policy: $PolicyName"

# Enable backup protection for the VM
az backup protection enable-for-vm `
  --vault-name $VaultName `
  --resource-group $VaultResourceGroup `
  --vm $VmName `
  --vm-resource-group $VmResourceGroup `
  --policy-name $PolicyName

if ($LASTEXITCODE -eq 0) {
  Write-Host "✅ Backup enabled successfully for $VmName" -ForegroundColor Green
} else {
  Write-Host "❌ Failed to enable backup for $VmName" -ForegroundColor Red
  exit 1
}
