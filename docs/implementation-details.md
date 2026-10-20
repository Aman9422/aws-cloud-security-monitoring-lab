# Implementation Details

## Environment

| Attribute | Recorded value |
|---|---|
| AWS Region used for the lab | Asia Pacific (Sydney), `ap-southeast-2` |
| CloudTrail trail | `Cloudsec-lab-trail` |
| Log archive | Amazon S3 destination; bucket identifier withheld from public documentation |
| CloudWatch Logs group | `/aws/cloudtrail/security-lab` |
| CloudWatch Logs retention | 7 days |
| SNS topic | `cloudsec-lab-alerts` |
| Least-privilege test identity | `cloudsec-lab-reader` |

The trail is configured as a multi-region trail and delivers CloudTrail records to both an S3 archive and the CloudWatch Logs group. Log file validation is enabled.

## Least-privilege policy model

The restricted test identity is permitted to list objects in one designated test bucket and retrieve objects from that bucket. It is not granted account-wide bucket enumeration through `s3:ListAllMyBuckets`.

The effective policy model uses resource-scoped permissions:

- `s3:ListBucket` on the designated bucket ARN.
- `s3:GetObject` on objects within that bucket.
- No allow statement for `s3:ListAllMyBuckets`.

The observed positive test listed bucket objects and retrieved `test.txt`. The negative test was denied as expected.

## Detection configuration

### Unauthorized API calls

| Attribute | Value |
|---|---|
| Metric filter | `UnauthorizedApiCallsFilter` |
| Metric namespace and name | `CloudSecLab / UnauthorizedApiCalls` |
| Alarm | `UnauthorizedApiCallsAlarm` |
| Evaluation | Sum over 5 minutes |
| Threshold | At least 1 metric unit |
| Signal | AWS events with `UnauthorizedOperation` or `AccessDenied*` error codes |

Filter pattern:

```text
{($.errorCode="*UnauthorizedOperation") || ($.errorCode="AccessDenied*")}
```

### Failed console sign-ins

| Attribute | Value |
|---|---|
| Metric filter | `ConsoleLoginFailuresFilter` |
| Metric namespace and name | `CloudSecLab / ConsoleLoginFailures` |
| Alarm | `ConsoleLoginFailuresAlarm` |
| Evaluation | Sum over 5 minutes |
| Threshold | At least 3 metric units |
| Intended signal | A failed AWS `ConsoleLogin` event matching the configured JSON fields |

Filter pattern:

```text
{ ($.eventSource = "signin.amazonaws.com") && ($.eventName = "ConsoleLogin") && ($.responseElements.ConsoleLogin = "Failure") }
```

The filter and alarm are configured. Actual failed-login event matching has not been verified because the investigated Sydney Event history view returned no `ConsoleLogin` records. The manual alarm-state test validates the alarm action path only.

## Notification path

Both alarms are configured with the SNS topic `cloudsec-lab-alerts`. The email subscription is confirmed. An email was received when the unauthorized API alarm was triggered by a real denied API request. A separate manual alarm-state change also produced an email for the ConsoleLogin alarm.

## Representative validation commands

The commands below record the CLI operations used in the lab. They assume an AWS CLI profile already configured with the restricted test identity and a placeholder replaced with the designated lab bucket name.

```bash
aws sts get-caller-identity --profile cloudsec-lab-reader
aws s3api list-objects-v2 --bucket REPLACE_WITH_LAB_BUCKET --profile cloudsec-lab-reader
aws s3api get-object --bucket REPLACE_WITH_LAB_BUCKET --key test.txt --profile cloudsec-lab-reader test-download.txt
aws s3api list-buckets --profile cloudsec-lab-reader
```

The first three operations establish identity and permitted object access. The final operation is expected to return `AccessDenied` because account-wide bucket listing is outside the test identity's policy.

## Configuration considerations

CloudWatch Logs retention is 7 days. S3 archive retention is independent of that setting. Explicit SSE-KMS configuration for the CloudTrail destination had not been enabled at the time of the recorded review; the bucket's default encryption configuration was not treated as verified by that observation.

This configuration represents a learning lab. Production use would require further review of encryption, access boundaries, retention, alert coverage, incident handling, and cost controls.
