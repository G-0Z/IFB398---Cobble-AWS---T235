# cobbled-aws

**IFB398 Capstone Project - P608 / R014.1**
Host organisation: Cyber Security Centre

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
+ **Infrastructure as Code:** TBC — Terraform, AWS CloudFormation, or AWS CDK
+ **Containers/hosting:** Docker, ECS/EKS (as applicable)
+ **CI/CD:** GitHub Actions or AWS CodePipeline

## Repository structure

Structure will be added as the project develops (e.g. `/architecture`, `/infrastructure`, `/docs`, `/runbooks`).

## Status

🚧 Early setup — repository and organisation scaffolding in progress.

## Team

IFB398 — Tutorial group T235
