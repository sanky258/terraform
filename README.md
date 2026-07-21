# Azure VM via Terraform + GitHub Actions

A learning project that deploys an Azure VM through Infrastructure-as-Code
and a CI/CD pipeline, instead of the Portal. This mirrors how most
companies actually manage cloud infra.

## Architecture
- **Terraform** — defines the VM, network, NSG, public IP (all in `terraform/`)
- **Remote state** — stored in an Azure Storage Account (not locally)
- **GitHub Actions** — runs `terraform plan` on every PR, `terraform apply` on merge to `main`
- **OIDC login** — GitHub authenticates to Azure via a federated credential, no secrets stored

---

## Step 1 — One-time bootstrap (do this manually, once)

You need a place for Terraform to store its state file, and an identity
GitHub Actions can use to log into Azure. Run these from WSL after `az login`:

```bash
# Variables — change the storage account name (must be globally unique)
RG_STATE="rg-tfstate"
STORAGE_ACCOUNT="sttfstate$RANDOM"   # note this value, you need it in backend.tf
LOCATION="canadacentral"
CONTAINER="tfstate"

# 1. Create resource group + storage account + container for state
az group create --name $RG_STATE --location $LOCATION
az storage account create --name $STORAGE_ACCOUNT --resource-group $RG_STATE \
  --location $LOCATION --sku Standard_LRS --encryption-services blob
az storage container create --name $CONTAINER --account-name $STORAGE_ACCOUNT

# 2. Create an Azure AD App Registration for GitHub OIDC
APP_ID=$(az ad app create --display-name "github-actions-terraform" --query appId -o tsv)
az ad sp create --id $APP_ID

# 3. Give it Contributor rights on your subscription (or scope to a resource group)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az role assignment create --assignee $APP_ID --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# 4. Create a federated credential trusting your GitHub repo
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Optional: add a second one scoped to pull_request so plan works on PRs too
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-pull-request",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'

echo "Client ID: $APP_ID"
echo "Tenant ID: $(az account show --query tenantId -o tsv)"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Storage Account: $STORAGE_ACCOUNT"
```

Update `terraform/backend.tf` with your real `storage_account_name`.

## Step 2 — Add GitHub repo secrets

In your repo → Settings → Secrets and variables → Actions, add:

| Secret name             | Value                              |
|--------------------------|-------------------------------------|
| `AZURE_CLIENT_ID`        | the `APP_ID` from above             |
| `AZURE_TENANT_ID`        | your tenant ID                      |
| `AZURE_SUBSCRIPTION_ID`  | your subscription ID                |
| `VM_SSH_PUBLIC_KEY`      | contents of your `~/.ssh/id_rsa.pub`|

No client secret is stored anywhere — that's the point of OIDC.

## Step 3 — Test locally first

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # then fill in your SSH key
terraform init
terraform plan
terraform apply
```

Confirm the VM shows up and you can `ssh` into it using the output command.
Then `terraform destroy` to tear it down before moving to the pipeline (avoid double-paying for resources).

## Step 4 — Push to GitHub and let the pipeline run

```bash
git init
git add .
git commit -m "Initial Terraform Azure VM setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

- Open a PR that changes something in `terraform/` (e.g. bump `vm_size`) → the workflow posts a plan.
- Merge to `main` → the workflow applies automatically.

## Using Claude Code here
From this folder, run `claude` and try prompts like:
- "Add an Azure Bastion host instead of a public IP for SSH access"
- "Add a dev/prod tfvars split using GitHub Actions environments"
- "Review this Terraform for security best practices"

Claude Code can edit these files directly, run `terraform plan` for you via the
bash tool, and explain any errors — a good way to practice the IaC workflow interactively.

## Next steps for job-readiness
- Move NSG rule to your IP only (`source_address_prefix`) instead of `*`
- Split into modules (`modules/network`, `modules/compute`)
- Add `terraform-docs` and `tflint`/`checkov` steps to the pipeline
- Try the same deployment in Bicep to compare the two approaches
