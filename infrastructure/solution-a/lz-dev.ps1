# Landing zone + dev demo in one command (runbooks/demo-landing-zone-dev.md).
#
#   .\lz-dev.ps1 up       steps 1-4: people, organisation, security, dev. Safe to re-run.
#   .\lz-dev.ps1 down     step 7: destroys dev and security. Keeps people, accounts, guardrails.
#   .\lz-dev.ps1 status   what's running, per account.
#
# Never creates an account that already exists, never closes one: accounts
# have prevent_destroy, and `up` refuses any step-2 plan that deletes anything.
# Sign in first: aws sso login --profile AdministratorAccess-669591255093
param([Parameter(Mandatory)][ValidateSet('up', 'down', 'status')][string]$Action)

$ErrorActionPreference = 'Stop'
if (-not $env:AWS_PROFILE) { $env:AWS_PROFILE = 'AdministratorAccess-669591255093' }
$env:AWS_REGION = 'ap-southeast-2'

$mgmt     = '669591255093'
$lz       = "$PSScriptRoot\landing-zone"
$people   = "$lz\identity"
$org      = "$lz\1-organization"
$sec      = "$lz\2-security"
$workload = "$PSScriptRoot\workload"
$ev       = "$PSScriptRoot\evidence"
$log      = "$ev\lz-dev-$Action-$(Get-Date -Format yyyyMMdd-HHmm).txt"
New-Item -ItemType Directory -Force $ev | Out-Null

# Shows each line and appends it to $log as UTF-8 (5.1's Tee-Object writes UTF-16, which GitHub shows as binary).
filter log { $_; Add-Content -LiteralPath $log -Value $_ -Encoding UTF8 }

# Runs terraform in $dir, shows and logs its output, stops on failure.
# cmd /c because PowerShell 5.1 turns a native command's stderr into errors.
function tf($dir, $cmd) {
  "`n>> terraform $cmd   ($(Split-Path $dir -Leaf))" | log
  cmd /c "terraform -chdir=`"$dir`" $cmd 2>&1" | log
  if ($LASTEXITCODE) { throw "terraform $cmd failed in $dir (exit $LASTEXITCODE). Log: $log" }
}

# Runs a block inside a member account, then switches back to the management account.
function Invoke-InAccount($account, [scriptblock]$do) {
  $c = aws sts assume-role --role-arn "arn:aws:iam::${account}:role/OrganizationAccountAccessRole" --role-session-name lz-dev --query Credentials --output json | ConvertFrom-Json
  if (-not $c) { throw "Can't assume OrganizationAccountAccessRole in $account" }
  $env:AWS_ACCESS_KEY_ID = $c.AccessKeyId; $env:AWS_SECRET_ACCESS_KEY = $c.SecretAccessKey; $env:AWS_SESSION_TOKEN = $c.SessionToken
  try { & $do } finally { Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN }
}

function Get-AccountIds { terraform -chdir="$org" output -json account_ids | ConvertFrom-Json }

function Get-DevArgs {
  $bucket = cmd /c "terraform -chdir=`"$sec`" output -raw config_bucket_name 2>nul"
  $key    = cmd /c "terraform -chdir=`"$sec`" output -raw config_kms_key_arn 2>nul"
  # After security is gone its outputs are empty; destroy only needs a value.
  if ($LASTEXITCODE -or -not $key) { $bucket = 'none'; $key = 'none' }
  "-var-file=dev.tfvars -var account_id=$($ids.dev) -var assume_role_name=OrganizationAccountAccessRole " +
  "-var container_image=public.ecr.aws/nginx/nginx:stable -var read_only_root_filesystem=false " +
  "-var enable_github_deploy=false -var app_max_count=2 -var alert_email=n11543027@qut.edu.au " +
  "-var config_bucket_name=$bucket -var config_kms_key_arn=$key"
}

# Removes delegated administrators that point at closed accounts: they block step 3.
function Remove-StaleDelegatedAdmins {
  $active = aws organizations list-accounts --query "Accounts[?Status=='ACTIVE'].Id" --output json | ConvertFrom-Json
  $admins = aws organizations list-delegated-administrators --query "DelegatedAdministrators[].Id" --output json | ConvertFrom-Json
  foreach ($a in $admins | Where-Object { $active -notcontains $_ }) {
    "Removing stale delegated administrator $a" | log
    foreach ($s in 'guardduty.amazonaws.com', 'securityhub.amazonaws.com', 'config.amazonaws.com', 'access-analyzer.amazonaws.com') {
      cmd /c "aws organizations deregister-delegated-administrator --account-id $a --service-principal $s 2>nul"
    }
  }
}

function Show-Row($name, $id) {
  $gd  = aws guardduty list-detectors --query DetectorIds --output text
  $sh  = cmd /c "aws securityhub describe-hub --query HubArn --output text 2>nul"
  $cfg = aws configservice describe-configuration-recorders --query "ConfigurationRecorders[].name" --output text
  "{0,-16} {1}  GuardDuty: {2,-5}  SecurityHub: {3,-5}  Config: {4}" -f $name, $id, [bool]$gd, [bool]$sh, [bool]$cfg
}

function Show-Status {
  "Delegated admins: $(aws organizations list-delegated-administrators --query 'DelegatedAdministrators[].Id' --output text)"
  # account_ids lists member accounts only; the management account uses the current sign-in.
  Show-Row 'management' $mgmt
  foreach ($p in $ids.PSObject.Properties) { Invoke-InAccount $p.Value { Show-Row $p.Name $p.Value } }
  'management GuardDuty is True while Solution B is deployed: it owns that detector.'
  $url = cmd /c "terraform -chdir=`"$workload`" output -raw app_url 2>nul"
  if (-not $LASTEXITCODE -and $url) { "Dev app: $url" } else { 'Dev app: not deployed' }
}

# --- Settings files (kept off GitHub) present? --------------------------------
$missing = "$people\settings.auto.tfvars", "$people\users.csv", "$org\settings.auto.tfvars", "$sec\settings.auto.tfvars" |
  Where-Object { -not (Test-Path $_) }
if ($missing) { throw "Missing settings files (not in Git; ask the team for copies):`n$($missing -join "`n")" }

# --- Signed in as the management admin? -------------------------------------
$who = aws sts get-caller-identity --query Account --output text
if ($who -ne $mgmt) { throw "Signed in to '$who', not $mgmt. Run: aws sso login --profile $env:AWS_PROFILE" }

tf $org 'init -input=false -no-color'
tf $sec 'init -input=false -no-color'
tf $workload 'init -input=false -no-color -reconfigure -backend-config=key=solution-a/workload/dev/terraform.tfstate'

switch ($Action) {
  'up' {
    # 1. People (free, kept)
    tf $people 'init -input=false -no-color'
    tf $people 'apply -auto-approve -input=false -no-color'

    # 2. Organisation (free, kept). Refuse any plan that deletes or replaces.
    if (-not (terraform -chdir="$org" state list | Select-String -SimpleMatch 'aws_organizations_organization.this')) {
      tf $org 'import -input=false -no-color aws_organizations_organization.this o-b60hme0nfl'
    }
    # AWS allows 5 SCPs per target. The hand-made DenyLeaveAndCloseAccount is covered by deny-leave-organization.
    $root = aws organizations list-roots --query "Roots[0].Id" --output text
    $manual = aws organizations list-policies-for-target --target-id $root --filter SERVICE_CONTROL_POLICY --query "Policies[?Name=='DenyLeaveAndCloseAccount'].Id" --output text
    if ($manual) { throw "Detach the hand-made SCP first (deny-leave-organization replaces it): aws organizations detach-policy --policy-id $manual --target-id $root" }
    tf $org 'plan -input=false -no-color -out=org.tfplan'
    $deletes = (terraform -chdir="$org" show -json org.tfplan | ConvertFrom-Json).resource_changes |
      Where-Object { $_.change.actions -contains 'delete' }
    if ($deletes) { throw "Step 2 plan would delete $($deletes.address -join ', '). Not applying: read $log" }
    tf $org 'apply -input=false -no-color org.tfplan'
    $ids = Get-AccountIds

    # 3. Security (costs money, torn down)
    Remove-StaleDelegatedAdmins
    tf $sec "apply -auto-approve -input=false -no-color -var security_account_id=$($ids.security)"

    # 4. Dev (costs money, torn down)
    tf $workload "apply -auto-approve -input=false -no-color $(Get-DevArgs)"

    $url = terraform -chdir="$workload" output -raw app_url
    foreach ($i in 1..20) {
      try { if ((Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 10).StatusCode -eq 200) { break } } catch {}
      if ($i -eq 20) { Write-Warning "$url isn't answering 200 yet. ECS > service > Tasks shows why." }
      Start-Sleep 30
    }
    "`nUp. App: $url"
    'Confirm the "AWS Notification - Subscription Confirmation" email in n11543027@qut.edu.au, or no alerts arrive.'
  }

  'down' {
    $ids = Get-AccountIds

    # 7.1 Dev, then 7.2 security (retried once: a last log file can land mid-delete)
    tf $workload "destroy -auto-approve -input=false -no-color $(Get-DevArgs)"
    # GuardDuty refuses to remove members while auto-enable is ALL; the next `up` sets it back.
    Invoke-InAccount $ids.security {
      $d = aws guardduty list-detectors --query "DetectorIds[0]" --output text
      if ($d -and $d -ne 'None') { aws guardduty update-organization-configuration --detector-id $d --auto-enable-organization-members NONE }
    }
    try { tf $sec "destroy -auto-approve -input=false -no-color -var security_account_id=$($ids.security)" }
    catch { 'Retrying security destroy once' | log
            tf $sec "destroy -auto-approve -input=false -no-color -var security_account_id=$($ids.security)" }

    # 7.3 Handing GuardDuty and Security Hub back leaves them on (and billing) in each member.
    foreach ($p in $ids.PSObject.Properties | Where-Object Name -ne 'security') {
      Invoke-InAccount $p.Value {
        foreach ($d in (aws guardduty list-detectors --query DetectorIds --output text) -split '\s+') {
          if ($d) { aws guardduty delete-detector --detector-id $d }
        }
        cmd /c "aws securityhub disable-security-hub 2>nul" | Out-Null
      }
    }
    # The management account isn't in account_ids, so 7.3 missed it and its detector kept billing.
    # Leave Solution B's detector alone (tagged Environment=poc); anything else is the landing zone's.
    foreach ($d in (aws guardduty list-detectors --query DetectorIds --output text) -split '\s+') {
      if ($d -and (aws guardduty get-detector --detector-id $d --query Tags.Environment --output text) -ne 'poc') {
        "Deleting landing-zone GuardDuty detector $d in the management account" | log
        aws guardduty delete-detector --detector-id $d
      }
    }
    cmd /c "aws securityhub disable-security-hub 2>nul" | Out-Null
    "`nDown. Everything below should be False; the accounts stay for the next run:"
    Show-Status
  }

  'status' { $ids = Get-AccountIds; Show-Status }
}
