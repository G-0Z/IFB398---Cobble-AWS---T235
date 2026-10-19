# Threat Model and Risk Assessment

-**Status:** Draft
-**Date:** 2026-10-10
-**Author:** Timothy Hartmann
-**Reviewed by:** T235

## 1. Purpose and Scope

This document provides a practical threat model and risk assessment for the proposed Cobbled AWS environment. Its purpose is to identify key cloud security threats that could affect the confidentiality, integrity and availability of the platform, and to document practical controls that can reduce those risks. 

This assessment focuses on the areas considered most relevant to the Cobled architecture and Proof of Concept (PoC), including:

- Multi-Tenancy and unauthorised access between tenants 
- Privileged access to AWS resources abd administrative functions
- Public and internal API exposure
- Protection of application data, credentials and secrets
- Service availability and resilience
- Infrastructure and Terraform configuration risks
- Logging, monitoring and recovery

The assessment considers both the current PoC and the proposed production architecure. The PoC is intentionally lightweight and cost-conscious, while the target production platform includes stronger availability, identity and operational controls. 

This document is intended to support Phase 1 security analysis and Phase 2 implementation planning. It is not a formal test, compliance or complete production security assessement. Risks and controls should be reviewed again as the architecture and deployed environment mature.

## 2. System Context

Cobbled is designed as a modular, multi-tenant platform where independently deployable modules own their frontend components, APIs, data stores and release lifecycle. 

The proposed AWS design seperates the platform across dedicated accounts for managment, security, shared services, development stagin and production. This separation reduces the impact of configuration errors or security incidents by preventing development andproduction workloads from sharing the same security boundary.

Only the public edge of the platform is intended to be directly accessible from the internet. Requests pass through the web firewall and load balancer before reaching application services running on ECS Fargate within private subnts. The database is also private and has no direct orute to the internet. 

The production design also aims to use short-lived AWS credentials, single sign-on and MFA rather than standing passwords or access keys

## 3. Assets to Protect

The following assets have been identified as important to the confidentiality, integrity and availability of Cobbled:

| Asset | Importance |
|---|---|
| Tenant data | Information belonging to one client must remain protected from other tenants and unauthorised users. |
| User identities and permissions | Used to determine who can access the platform and what actions they are allowed to perform. |
| AWS accounts and privileged roles | Compromise could allow modification, deletion or exposure of platform resources. |
| Application APIs | Provide access to backend functions and may expose tenant data if improperly secured. |
| Database | Stores application and tenant information and must remain private and protected. |
| Secrets and credentials | Includes application secrets, database credentials and authentication information. |
| Terraform configuration and state | Controls the AWS environment and can create, modify or destroy infrastructure. |
| Source code and deployment pipeline | Changes may be promoted into AWS and therefore require controlled review and deployment. |
| Logs and security records | Required for monitoring, troubleshooting and investigation of security events. |
| Backups | Required to recover from accidental deletion, corruption or service failure. |

## 4. Risk Assessment

Risks are assessed using a likelihood and impact rating from 1 to 5.

### Likelihood

| Score | Rating | Description |
|---:|---|---|
| 1 | Rare | Unlikely to occur. |
| 2 | Unlikely | Could occur, but is not expected regularly. |
| 3 | Possible | A realistic scenario that may occur. |
| 4 | Likely | Expected to occur unless controls are effective. |
| 5 | Almost Certain | Expected to occur frequently or repeatedly. |

### Impact

| Score | Rating | Description |
|---:|---|---|
| 1 | Insignificant | Minimal operational or security impact. |
| 2 | Minor | Limited impact with straightforward recovery. |
| 3 | Moderate | Noticeable impact requiring intervention. |
| 4 | Major | Significant service disruption or security impact. |
| 5 | Severe | Major data exposure, infrastructure compromise or prolonged outage. |

Risk score is calculated as:

`Likelihood × Impact`

| Score | Risk Rating |
|---:|---|
| 1-4 | Low |
| 5-9 | Medium |
| 10-16 | High |
| 17-25 | Critical |

The initial risk represents the level of exposure before controls are considered. Residual risk represents the expected risk remaining after the proposed controls are implemented.

## 5. Threat and Risk Assessment

| ID | Threat | Likelihood | Impact | Initial Risk | Key Mitigations | Residual Risk |
|---|---|---:|---:|---|---|---|
| T01 | Cross-tenant data access | 3 | 5 | High (15) | Tenant validation, application access controls and database isolation | Low |
| T02 | Compromise of privileged AWS access | 3 | 5 | High (15) | SSO, MFA, short-lived roles, least privilege and audit logging | Medium |
| T03 | Unauthorised or malicious API access | 3 | 5 | High (15) | Web firewall, authentication, authorisation, request validation and rate limiting | Medium |
| T04 | Exposure of credentials or secrets | 3 | 5 | High (15) | Secrets management, short-lived credentials and no secrets stored in source control | Low |
| T05 | Database exposure | 2 | 5 | High (10) | Private database, restricted network access and encryption | Low |
| T06 | Service outage or failed deployment | 3 | 4 | High (12) | Health checks, monitoring, rollback procedures and environment separation | Medium |
| T07 | Terraform or AWS misconfiguration | 3 | 4 | High (12) | Pull requests, Terraform plan review, automated validation and account guardrails | Medium |
| T08 | Loss of logs or security evidence | 3 | 4 | High (12) | Central security account, CloudTrail, monitoring and protected logging services | Medium |
| T09 | Backup failure or unrecoverable data loss | 3 | 5 | High (15) | Automated backup, restore testing and future off-account backup copies | Medium |
| T10 | Compromise of the deployment pipeline | 2 | 5 | High (10) | GitHub short-lived roles, branch review and restricted deployment permissions | Medium 

## 6. Key Threat Areas

### 6.1 Multi-Tenacy

Multi-tenancy is a high-impact risk because Cobbled may host information belonging to multiple clients. A failure in tenant isolation could allow one client to access information belonging to another.

Controls should ensure that tenant identify is validated before data is accesssed and that application and database permissions prevent unauthorised cross-tenant access.

Key controls include:

- Validate tenant identity before processing requests.
- Prevent users from selecting or modifying another tenant's identity.
- Restrict access to tenant data at both the application and database layers.
- Test that incorrect tenant identifiers are rejected.
- Review tenant isolation as new modules are introduced.

### 6.2 Privileged Access

 Privileged AWS access could allow an attacker or compromised account to modify security controls, retrieve data or destroy resources.

The target design reduces this risk by removing long-lived credentials and using single sign-on, MFA and temporary roles.

Key controls include:

- Require MFA for privileged access.
- Use IAM Identity Center for human access.
- Use short-lived AWS sessions rather than long-lived access keys.
- Apply least-privilege permissions.
- Separate platform administrator, developer and auditor access.
- Record privileged activity through CloudTrail.

### 6.3 API Exposure

Application APIs are a major entry point into Cobbled and may be targeted through unauthorised requests, malformed input, excessive requests or attempts to bypass authentication.

The proposed architecture limits public exposure by allowing internet traffic to enter only through the public edge.

Key controls include:

- Authenticate and authorise API requests.
- Place application workloads inside private subnets.
- Use the web firewall to filter malicious traffic.
- Apply request validation and rate limiting.
- Prevent direct internet access to application containers and databases.

### 6.4 Data Protection

Tenant and application data must remain protected both while stored and while being transmitted.

Secrets and credentials should not be stored directly in source code, Terraform files or application logs.

Key controls include:

- Encrypt sensitive data at rest and in transit.
- Store credentials and application secrets using an approved secrets-management service.
- Keep databases private.
- Restrict database access to approved application services.
- Avoid storing secrets or unnecessary sensitive information in logs.

### 6.5 Service Availability

The platform must remain available when individual components fail or when deployments introduce errors.

Environment separation also reduces the risk that changes made during development affect production services.

Key controls include:

- Separate development, staging and production environments.
- Monitor application and infrastructure health.
- Use health checks and automated recovery where possible.
- Maintain rollback procedures for failed deployments.
- Maintain backups and regularly test recovery.

### 6.6 Infrastructure and Configuration Risk

Terraform provides a repeatable method for managing AWS infrastructure, but an incorrect configuration could affect many resources at once.

Key controls include:

- Use feature branches and pull requests.
- Review Terraform plans before changes are applied.
- Restrict deployments to approved AWS accounts and regions.
- Use automated Terraform validation and security scanning.
- Test infrastructure changes before production deployment.
- Prevent routine manual changes that bypass Infrastructure-as-Code.

## 7. Current PoC Limitations and Residual Risk



## 8. Phase 2 Security Actions




## 9. Conclusion


