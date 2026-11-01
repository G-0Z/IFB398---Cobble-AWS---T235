# IFB398-T235 Meeting Minutes

## Client Meeting 2: 14 September 2026

IFB398 Capstone · Team T235 · P608 Cobbled AWS Platform Configuration

Wayne set clear expectations for the report: implementable recommendations, documented issues and solutions, and a 1 month and 3 month implementation option. All four team members attended.

| Item | Detail |
| --- | --- |
| Date | Monday 14 September 2026 (Week 9) |
| Format | Online |
| Attendees | Wayne (Cyber Security Centre); Khai Do, Max Gosling, Jacob Hardcastle, Timothy Hartmann |
| Sprint | P1 S3 (14 to 27 Sep), first day |
| Purpose | Review design direction; agree report expectations and meeting cadence |

### Discussed

- Environments: Cobble’s development environment stays on DigitalOcean until it is ready to move to AWS. The app can load from GitHub rather than directly from DigitalOcean.
- Commercial model: once in production, each client pays for its own storage at the level it chooses.
- Design review: the team’s ECS vs EKS comparison and pricing comparison between services. The current architecture diagram had no WAF.

### Requested by Wayne

- Recommendations that can actually be implemented.
- Issues and their solutions documented.
- An implementation timeframe with 1 month and 3 month options.
- A schedule covering this semester and next.

### Agreed

- Client meetings at least fortnightly, weekly only if needed, so the rest of the time goes into the report.

### Follow-up

Each request is reflected in the Solution A vs B comparison (6 October 2026).

| Feedback | What the team did |
| --- | --- |
| Show 1 month and 3 month options | Both timeframes set out week by week in the comparison |
| Make recommendations implementable | Solution B deployed and tested; Solution A written, validated and tested as Terraform, ready to roll out in four steps |
| Document issues and solutions | Four known Solution A gaps and all Checkov findings recorded, with planned fixes |
| No WAF in the diagram | WAF added to Solution A’s staging and production environments |
| Cover this semester and next | Phase 1 (Semester 2 2026) and Phase 2 (Semester 1 2027) plan |
