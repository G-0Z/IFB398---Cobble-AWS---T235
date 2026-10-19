# Demo links: Solution A evidence

One click each. Every link goes through the access portal, signs you in to
the right account as `CobblePlatformAdmin`, and opens the page in Sydney.
Sign in to the portal once first: https://d-97679ebd7b.awsapps.com/start

> [!IMPORTANT]
> These only show something while the landing zone is up. Run `.\lz-dev.ps1 up`
> first ([quickstart](../../runbooks/demo-landing-zone-quickstart.md)); the
> organisation, guardrails and sign-in links work at any time.

## Management account: the organisation

| Show | What it proves |
|---|---|
| [Accounts in their folders](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=669591255093&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fus-east-1.console.aws.amazon.com%2Forganizations%2Fv2%2Fhome%2Faccounts) | Security, Infrastructure, Workloads > NonProduction / Production, each with its account |
| [The 4 guardrails (SCPs)](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=669591255093&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fus-east-1.console.aws.amazon.com%2Forganizations%2Fv2%2Fhome%2Fpolicies%2Fservice-control-policy) | All four attached to Root: stay in Australia, no root user, security stays on, no leaving |
| [Single sign-on](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=669591255093&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fsinglesignon%2Fhome%3Fregion%3Dap-southeast-2) | Groups and Permission sets: the 3 `cobble-` groups, `CobblePlatformAdmin`, `CobbleDeveloper`, `CobbleReadOnly` |
| [Organisation audit trail](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=669591255093&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fcloudtrailv2%2Fhome%3Fregion%3Dap-southeast-2%23%2Ftrails%2Farn%3Aaws%3Acloudtrail%3Aap-southeast-2%3A669591255093%3Atrail%2Fcobble-organization-trail) | `cobble-organization-trail`: every account, every region, log file validation on |
| [Cost so far](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=669591255093&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fus-east-1.console.aws.amazon.com%2Fcostmanagement%2Fhome%23%2Fcost-explorer) | What the demo days cost |

## Security account: central logging and detection

| Show | What it proves |
|---|---|
| [GuardDuty: enrolled accounts](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fguardduty%2Fhome%3Fregion%3Dap-southeast-2%23%2Flinked-accounts) | The other Cobble accounts enrolled, managed from here |
| [GuardDuty: findings](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fguardduty%2Fhome%3Fregion%3Dap-southeast-2%23%2Ffindings) | Any sample finding raised for the demo |
| [Security Hub: standards](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fsecurityhub%2Fhome%3Fregion%3Dap-southeast-2%23%2Fstandards) | CIS AWS Foundations 3.0.0 and AWS Foundational Security Best Practices (scores fill in over a few hours) |
| [Config: organisation aggregator](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fconfig%2Fhome%3Fregion%3Dap-southeast-2%23%2Faggregators) | `cobble-organization`: every account reporting |
| [Locked audit logs (Object Lock)](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fs3.console.aws.amazon.com%2Fs3%2Fbuckets%2Fcobble-audit-logs-021407434891%3Fregion%3Dap-southeast-2%26tab%3Dproperties) | `cobble-audit-logs-…`: Object Lock enabled, with retention |
| [Access Analyzer](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Faccess-analyzer%2Fhome%3Fregion%3Dap-southeast-2%23%2Fanalyzers) | `cobble-organization` analyser across the organisation |
| [Alert topic](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fsns%2Fv3%2Fhome%3Fregion%3Dap-southeast-2%23%2Ftopic%2Farn%3Aaws%3Asns%3Aap-southeast-2%3A021407434891%3Acobble-security-alerts) | `cobble-security-alerts`: high and critical findings emailed |

## Dev account: the workload

| Show | What it proves |
|---|---|
| [The app's load balancer](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fec2%2Fhome%3Fregion%3Dap-southeast-2%23LoadBalancers%3Asearch%3Dcobble-dev-alb) | Copy its DNS name: that's the `App:` address |
| [Subnets in three layers](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fvpcconsole%2Fhome%3Fregion%3Dap-southeast-2%23subnets%3Asearch%3Dcobble-dev) | Public, private and database subnets, two of each |
| [VPC flow logs](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fvpcconsole%2Fhome%3Fregion%3Dap-southeast-2%23vpcs%3Asearch%3Dcobble-dev) | Select the VPC, then the Flow logs tab: active |
| [Web servers (ECS tasks)](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fecs%2Fv2%2Fclusters%2Fcobble-dev%2Fservices%2Fcobble-dev%2Ftasks%3Fregion%3Dap-southeast-2) | Running tasks; open one > Networking: private IP only |
| [Database](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Frds%2Fhome%3Fregion%3Dap-southeast-2%23database%3Aid%3Dcobble-dev%3Bis-cluster%3Dfalse) | Connectivity: not publicly accessible. Configuration: encrypted with the `cobble-dev` key |
| [Database password](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fsecretsmanager%2Flistsecrets%3Fregion%3Dap-southeast-2) | Kept by AWS in Secrets Manager (don't reveal the value) |
| [Data bucket: encryption](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fs3.console.aws.amazon.com%2Fs3%2Fbuckets%2Fcobble-dev-data-740667376104%3Fregion%3Dap-southeast-2%26tab%3Dproperties) | KMS encryption and versioning on |
| [Data bucket: public access](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fs3.console.aws.amazon.com%2Fs3%2Fbuckets%2Fcobble-dev-data-740667376104%3Fregion%3Dap-southeast-2%26tab%3Dpermissions) | Block all public access: On |
| [Budget](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fus-east-1.console.aws.amazon.com%2Fbilling%2Fhome%23%2Fbudgets) | `cobble-dev-monthly-cost` and its alert |
| [Guardrail test: bucket in London](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=740667376104&role_name=CobblePlatformAdmin&destination=https%3A%2F%2Fs3.console.aws.amazon.com%2Fs3%2Fbucket%2Fcreate%3Fregion%3Deu-west-2) | Try to create any bucket: refused, explicit deny in a service control policy |

## Access control working

[Security account as `CobbleReadOnly`](https://d-97679ebd7b.awsapps.com/start/#/console?account_id=021407434891&role_name=CobbleReadOnly&destination=https%3A%2F%2Fap-southeast-2.console.aws.amazon.com%2Fconsole%2Fhome%3Fregion%3Dap-southeast-2): a platform admin
isn't in the auditors group, so this shows "Account sign in error … No access".

## Outside AWS

| Show | What it proves |
|---|---|
| [Automatic checks on GitHub](https://github.com/G-0Z/IFB398---Cobble-AWS---T235/actions) | Every change formatted, validated, tested and scanned |
| [Run logs](../../infrastructure/solution-a/evidence/) | Each `up` and `down`, with resource counts |
| `.\lz-dev.ps1 status` | Run in `infrastructure/solution-a`: GuardDuty, Security Hub and Config per account, plus the `Dev app:` address |
