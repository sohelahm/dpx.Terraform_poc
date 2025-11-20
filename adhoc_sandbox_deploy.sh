#!/bin/bash
set -euo pipefail

### SETUP SECRETS (export these in your shell or set in this script securely)
# export JF_URL="https://msde-docker-prod.ms.com"
# export JF_ACCESS_TOKEN="YOUR_JFROG_TOKEN"
# export JF_USER="YOUR_JFROG_USERNAME"
# export REGION="us-east-1"              # or as needed
# export SANDBOX_NAME="mssandbox"        # optional
# export REF="feature/sandboxtest"       # branch, tag, or commit

### 1. Checkout code - if needed, update to fetch $REF from your repo
# git fetch origin "$REF"
# git checkout "$REF"

### 2. Install or ensure jfrog CLI is available (v2.75.0)
if ! command -v jf &> /dev/null; then
  echo "jfrog CLI not found! Install it manually or automate here."
  exit 1
else
  echo "jfrog CLI found: $(jf --version)"
fi

### 3. Setup jfrog config
echo "Configuring JFrog CLI"
jf config add msdeartprod --artifactory-url="$JF_URL/artifactory" --user="$JF_USER" --access-token="$JF_ACCESS_TOKEN" --overwrite

### 4. Download Terraform artifact (1.9.8)
echo "Downloading Terraform..."
jf rt dl --flat hashicorp-safe/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip
if [[ ! -f terraform_1.9.8_linux_amd64.zip ]]; then
  echo "File not found: terraform_1.9.8_linux_amd64.zip"
  exit 1
fi
unzip -qo terraform_1.9.8_linux_amd64.zip

### 5. Configure Terraform to use Artifactory mirror
mkdir -p ~/.terraform.d
cat <<EOF > ~/.terraformrc
provider_installation {
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
  network_mirror {
    url="https://msdeartprod-internal.ms.com/artifactory/api/terraform/terraform-all/providers/"
    include = ["*/*"]
  }
}
credentials "msdeartprod-internal.ms.com" {
  token = "$JF_ACCESS_TOKEN"
}
EOF

### 6. Terraform Init
echo "Running terraform init..."
ls -ltr
pwd
./terraform version
./terraform init

### 7. Terraform Validate
echo "Running terraform validate..."
./terraform validate

### 8. Terraform Plan
echo "Running terraform plan..."
./terraform plan

echo "All done! (Apply step is omitted for safety. Add it if you want auto-apply.)"
