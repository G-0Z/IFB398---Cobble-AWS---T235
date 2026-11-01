# ADR 0005: Containers on ECS Fargate, not Kubernetes (EKS)

- **Status:** Accepted
- **Date:** Sprint 2 (31 August to 13 September 2026)
- **Deciders:** T235

## Context

Cobble's modules will run as containers. The Implementation Guide (§7)
recommends EKS only when the team can run Kubernetes day to day. Sprint 2
compared ECS and EKS on features, operating effort and price.

## Options

| Option | For | Against |
|---|---|---|
| EKS | Kubernetes portability; the wider ecosystem | A cluster to upgrade and secure; a fixed control-plane charge; skills a small team doesn't have |
| ECS on EC2 | Cheaper at steady high load | Servers to patch and scale |
| **ECS on Fargate** | No servers or cluster upgrades; AWS patches the hosts | Fewer scheduling options than Kubernetes |

## Decision

ECS on Fargate, built by the
[`container-service`](../../infrastructure/modules/container-service/) module
(service, load balancer, web firewall, auto scaling).

## Consequences

- No hosts or cluster versions to patch. In the
  [patching matrix](../deliverables/deployment-operations.md), the container
  image is the only layer left to the team.
- The Guide's open decision "ECS or EKS" is answered
  ([landing zone design](../deliverables/landing-zone-design.md#open-decisions)).

**Revisit if** Cobble needs something only Kubernetes offers.
