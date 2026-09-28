# cobbled-aws

**IFB398 Capstone Project - P608 / R014.1**
Host organisation: QUT Client Company

## Overview

This project aims to design and prototype a secure AWS engineering and security foundation for the Cobble Platform - a proof-of-concept, modular, multi-tenant SaaS hosting platform for independently deployable microservices.

The scope of this project is not the Cobble application modules themselves. It is the cloud engineering, platform architecture, security controls, and operational foundations required to host Cobble safely and repeatably in AWS — in short, a secure AWS landing zone and deployment model.

## Goals

+ Design a reference architecture for hosting Cobble in AWS (environments, network zones, compute, storage, identity, logging, monitoring, backup, security boundaries)
+ Design a secure landing zone: AWS account/environment structure (dev, test, staging, production) with separation of duties and least-privilege access
+ Define security controls: IAM, MFA, secrets management, encryption, network segmentation, logging, monitoring, vulnerability management, incident response, backup/recovery
+ Build a working Infrastructure-as-Code prototype demonstrating repeatable deployment of core platform infrastructure
+ Document a deployment and operations model, including runbooks and support responsibilities
+ Produce a threat model and risk assessment covering multi-tenancy, privileged access, API exposure, data protection, and service availability
+ Map the design to relevant compliance frameworks (NIST CSF, Essential Eight, ISO 27001 concepts)

## Deliverables

1. AWS reference architecture
2. Secure landing zone design
3. Security control design
4. Infrastructure-as-Code prototype
5. Deployment and operations model
6. Threat model and risk assessment
7. Compliance and assurance mapping
8. Final stakeholder presentation

## Tech stack

+ **Cloud provider:** AWS (Organizations, Control Tower / landing zone concepts, IAM, VPC, KMS, Secrets Manager, CloudTrail, GuardDuty, Security Hub, Config, RDS, S3)
+ **Infrastructure as Code:** Terraform
+ **Containers/hosting:** Docker, ECS/EKS (as applicable)
+ **CI/CD:** GitHub Actions or AWS CodePipeline

## Repository structure

```
adr/                              Architecture decision records
docs/
  01-reference-architecture/      Deliverable 1
  02-landing-zone-design/         Deliverable 2
  03-security-controls/           Deliverable 3
  05-deployment-operations/       Deliverable 5
  06-threat-model/                Deliverable 6
  07-compliance-mapping/          Deliverable 7
  08-presentation/                Deliverable 8
infrastructure/                   Deliverable 4 (Infrastructure-as-Code prototype)
runbooks/                         Operational runbooks referenced by deliverable 5
```

Numbering follows the deliverables list above; `infrastructure/` covers deliverable 4
outside of `docs/`, so `docs/04-...` is intentionally absent. See `.github/CODEOWNERS`
for who owns each area.

## Status

🚧 In progress — Terraform PoC (deliverable 4) is deployed to the shared AWS
account with automated tests and CI. Other deliverables (docs/01-08) are
still scaffolding, see each folder's owner in `.github/CODEOWNERS`.

## Team

IFB398 — Tutorial group T235