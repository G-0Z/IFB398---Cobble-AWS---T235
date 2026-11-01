# ADR 0008: A load balancer with a web firewall, not CloudFront and API Gateway

- **Status:** Accepted
- **Date:** 2026-10-06
- **Deciders:** T235, following Wayne's design review

## Context

The Implementation Guide puts CloudFront and API Gateway in front of a
private load balancer. At the
[second client meeting](../project/phase-1-meetings.md#week-9-client-meeting-2) (14
September 2026), Wayne pointed out that the architecture diagram had no web
firewall. Cobble has no domain name or defined API routes yet.

## Decision

Each environment's front door is a public Application Load Balancer with
HTTPS. Staging and prod add AWS WAF, with managed rules and a rate limit.
The web servers and database stay in private subnets. The firewall is built
in [`container-service/waf.tf`](../../infrastructure/modules/container-service/waf.tf).

## Consequences

- The protection needed now, for less cost and fewer moving parts.
- No edge caching or per-route API controls until CloudFront and API Gateway
  are added.
- The WAF is in code but hasn't run live yet: the demo deploys dev, which
  leaves it off.

**Revisit when** Cobble's domain name and API routes exist.
