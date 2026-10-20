# Evidence Catalogue

The following screenshots are committed with the project and provide visual evidence of the AWS lab configuration and selected validation results.

| Evidence | Screenshot | What it demonstrates |
|---|---|---|
| CloudTrail configuration | [`cloudtrail-trail-config.png.png`](cloudtrail-trail-config.png.png) | Multi-region trail configuration and log delivery destinations |
| CloudWatch Logs | [`cloudwatch-log-group.png.png`](cloudwatch-log-group.png.png) | The `/aws/cloudtrail/security-lab` log group and its monitoring configuration |
| Console login alarm configuration | [`console-login-alarm.png.png`](console-login-alarm.png.png) | Configuration and current state of `ConsoleLoginFailuresAlarm`; this is not evidence of a real failed-login event matching the filter |
| Console login alarm notification test | [`console-login-manual-test-email.png.png`](console-login-manual-test-email.png.png) | Email received after a manual alarm-state test; verifies the alarm-action notification path only |
| IAM reader identity | [`iam-reader-user.png.png`](iam-reader-user.png.png) | The dedicated `cloudsec-lab-reader` IAM identity used for least-privilege validation |
| Least-privilege policy | [`least-privilege-policy.png.png`](least-privilege-policy.png.png) | Scope of the S3 read permissions used in the lab |
| Unauthorized API alarm | [`unauthorized-api-alarm.png.png`](unauthorized-api-alarm.png.png) | `UnauthorizedApiCallsAlarm` and its alarm state following the denied API request |
| Unauthorized API notification | [`unauthorized-api-alert-email.png.png`](unauthorized-api-alert-email.png.png) | Email alert associated with the verified unauthorized API detection workflow |

## Evidence interpretation

The unauthorized API screenshots support an end-to-end test: a restricted S3 operation was denied, the CloudTrail event was recorded, the CloudWatch alarm entered `ALARM`, an email notification arrived, and the alarm later returned to `OK`.

The ConsoleLogin screenshots support a narrower claim. The alarm is configured and its SNS email action was tested manually, but a matching real failed-console-login event and metric threshold breach were not observed in the investigated Event history view. The project therefore does not label that detection path as end-to-end verified.

Billing figures from the 20 October 2026 account review are documented in [Cost and Security Review](../docs/cost-and-security-review.md). A separate billing screenshot is not included in this evidence catalogue.
