#!/usr/bin/env bash
set -e

echo "🔍 System check shuru ho raha hai..."

# -------------------------
# Terraform pre-check
# -------------------------
if command -v terraform >/dev/null 2>&1; then
  echo "✅ terrafom already hai system pe"
  terraform version
  exit 0
fi

# -------------------------
# Confirmation helper
# -------------------------
confirm_action() {
  while true; do
    read -rp "$1 (y/n): " choice
    case "$choice" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *) echo "❌ sirf y ya n likho" ;;
    esac
  done
}

# -------------------------
# Root check (Linux only)
# -------------------------
if [[ "$OSTYPE" != "darwin"* && $EUID -ne 0 ]]; then
  echo "❌ bhai sudo ke bina kaam nahi chalega"
  exit 1
fi

# ==================================================
# 🍎 macOS
# ==================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "🍎 macOS detect ho gaya"
  echo "🔥 ab hoga terraform install ---- (macOS)"

  if ! command -v brew >/dev/null 2>&1; then
    echo "📦 Homebrew nahi mila, install ho raha hai..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -d "/opt/homebrew/bin" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi

  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform

  echo "✅ Terraform ready hai:"
  terraform version
  exit 0
fi

# ==================================================
# 🐧 Linux
# ==================================================
echo "🐧 Linux detect ho gaya"
. /etc/os-release

# ==================================================
# 🟡 Amazon Linux 2023 (SPECIAL CASE)
# ==================================================
if [[ "$NAME" == "Amazon Linux" && "$VERSION_ID" == "2023" ]]; then
  echo "🟡 Amazon Linux 2023 detect ho gaya"
  echo "🔥 ab hoga terraform install ---- (Manual binary)"

  if [[ -f /etc/yum.repos.d/hashicorp.repo ]]; then
    echo "⚠ Amazon Linux 2023 pe HashiCorp RPM repo supported nahi hai."

    if confirm_action "Kya aap HashiCorp repo uninstall karna chahte ho?"; then
      echo "🧹 HashiCorp repo remove ho raha hai..."
      rm -f /etc/yum.repos.d/hashicorp.repo
      dnf clean all
    else
      echo "❌ User ne mana kar diya. Terraform install abort."
      exit 1
    fi
  fi

  dnf install -y unzip jq

  TF_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
  echo "⬇ Terraform version: $TF_VERSION"

  curl -LO https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
  unzip terraform_${TF_VERSION}_linux_amd64.zip

  mv terraform /usr/local/bin/terraform
  chmod +x /usr/local/bin/terraform
  rm -f terraform_${TF_VERSION}_linux_amd64.zip

  echo "✅ Terraform ready hai:"
  terraform version
  exit 0
fi

# ==================================================
# Package manager detect
# ==================================================
if command -v apt >/dev/null 2>&1; then
  PM="apt"
elif command -v dnf >/dev/null 2>&1; then
  PM="dnf"
elif command -v yum >/dev/null 2>&1; then
  PM="yum"
elif command -v zypper >/dev/null 2>&1; then
  PM="zypper"
else
  echo "❌ koi supported package manager nahi mila"
  exit 1
fi

echo "🧰 Package manager mila: $PM"

# ==================================================
# Repo-based installs
# ==================================================
case "$PM" in
  apt)
    apt update
    apt install -y gnupg curl software-properties-common

    curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $VERSION_CODENAME main" \
      > /etc/apt/sources.list.d/hashicorp.list

    apt update
    echo "🔥 ab hoga terraform install ---- (Linux: apt)"
    apt install -y terraform
    ;;
  yum|dnf)
    yum install -y yum-utils
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    echo "🔥 ab hoga terraform install ---- (Linux: yum/dnf)"
    yum install -y terraform
    ;;
  zypper)
    zypper addrepo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    zypper refresh
    echo "🔥 ab hoga terraform install ---- (Linux: zypper)"
    zypper install -y terraform
    ;;
esac

# ==================================================
# PATH safety
# ==================================================
if ! command -v terraform >/dev/null 2>&1; then
  echo "⚠ terraform galat raste pr hai, fixing..."
  ln -s /usr/bin/terraform /usr/local/bin/terraform || true
fi

echo "✅ Terraform ready hai:"
terraform version

