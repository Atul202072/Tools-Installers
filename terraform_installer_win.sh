# ================================
# Terraform Windows Installer
# ================================

Write-Host "🔍 System check shuru ho raha hai..."

# -------------------------------
# Terraform pre-check
# -------------------------------
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    Write-Host "✅ terrafom already hai system pe"
    terraform version
    exit 0
}

# -------------------------------
# Confirmation helper
# -------------------------------
function Confirm-Action {
    param (
        [string]$Message
    )
    while ($true) {
        $choice = Read-Host "$Message (y/n)"
        switch ($choice.ToLower()) {
            "y" { return $true }
            "n" { return $false }
            default { Write-Host "❌ sirf y ya n likho" }
        }
    }
}

# -------------------------------
# Admin check
# -------------------------------
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ bhai PowerShell Administrator mode me chalao"
    exit 1
}

# -------------------------------
# Preferred: Winget install
# -------------------------------
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "🔥 ab hoga terraform install ---- (winget)"

    winget install -e --id Hashicorp.Terraform --accept-source-agreements --accept-package-agreements

    if (Get-Command terraform -ErrorAction SilentlyContinue) {
        Write-Host "✅ Terraform ready hai:"
        terraform version
        exit 0
    }
}

# -------------------------------
# Fallback: Manual binary install
# -------------------------------
Write-Host "⚠ winget available nahi hai, manual install ho raha hai"

if (-not (Confirm-Action "Kya aap manual Terraform install karna chahte ho?")) {
    Write-Host "❌ User ne mana kar diya. Install abort."
    exit 1
}

$InstallDir = "C:\Terraform"
$ZipPath = "$env:TEMP\terraform.zip"

# Create install directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

# Get latest Terraform version
$VersionInfo = Invoke-RestMethod "https://checkpoint-api.hashicorp.com/v1/check/terraform"
$TFVersion = $VersionInfo.current_version

Write-Host "⬇ Terraform version: $TFVersion"

$DownloadUrl = "https://releases.hashicorp.com/terraform/$TFVersion/terraform_${TFVersion}_windows_amd64.zip"

Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
Remove-Item $ZipPath

# -------------------------------
# PATH setup
# -------------------------------
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

if ($CurrentPath -notlike "*$InstallDir*") {
    Write-Host "⚠ terraform galat raste pr hai, fixing..."
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$CurrentPath;$InstallDir",
        "Machine"
    )
}

# Refresh PATH for current session
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")

# -------------------------------
# Verify install
# -------------------------------
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    Write-Host "✅ Terraform ready hai:"
    terraform version
} else {
    Write-Host "❌ Terraform install fail ho gaya"
    exit 1
}

# Set-ExecutionPolicy RemoteSigned -Scope Process
# .\terra.pst
C
D
.\terra.ps1
C
###
