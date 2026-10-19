# Screenshots for project evidence

Add sanitized screenshots here after redacting sensitive details.

Suggested evidence:
1. `cloudtrail-trail.png` — multi-region trail configuration and delivery destinations.
2. `cloudwatch-logs.png` — log streams from `/aws/cloudtrail/security-lab`.
3. `iam-access-denied.png` — denied `ListBuckets` test.
4. `unauthorized-api-alarm.png` — `UnauthorizedApiCallsAlarm` entering `ALARM` and, if practical, returning to `OK`.
5. `console-login-alarm-manual-test.png` — clearly captioned as a **manual alarm-action test**, not proof of a real failed-login event match.
6. `sns-email-alert.png` — redacted alert email.

Before committing, hide AWS account IDs, personal email addresses, IP addresses when not needed, sensitive object paths, and other identifying or confidential details. Never include access keys, secret keys, session tokens, passwords, or raw sensitive CloudTrail records.
