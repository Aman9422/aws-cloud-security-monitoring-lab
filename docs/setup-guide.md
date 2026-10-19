# Setup guide

This document records the lab setup and representative validation commands. Account-specific identifiers, the exact log bucket name, and the alert email are intentionally omitted.

## 1. Region

The lab was configured primarily in **Asia Pacific (Sydney), `ap-southeast-2`**. Keep the Region consistent when opening regional CloudWatch, SNS, and CloudTrail pages. Console sign-in event visibility can vary by user type and sign-in endpoint; if expected sign-in events are absent in Sydney, check the relevant CloudTrail documentation and other relevant Regions before changing the filter.

## 2. CloudTrail

The trail is named `Cloudsec-lab-trail` and is configured as a multi-region trail. It sends logs to an S3 archive and to the CloudWatch Logs group `/aws/cloudtrail/security-lab`.

Configuration checks:
1. Confirm the trail is logging management events.
2. Confirm the S3 destination is private and its bucket policy permits the required CloudTrail delivery.
3. Confirm log file validation is enabled.
4. Confirm the CloudWatch Logs destination and delivery role are configured.
5. Verify recent events appear in CloudWatch Logs streams.

Review current encryption and access settings before using this pattern elsewhere. During the recorded lab review, SSE-KMS encryption was not enabled as an explicit CloudTrail destination setting; review the bucket's actual default encryption configuration.

## 3. CloudWatch Logs retention

The log group `/aws/cloudtrail/security-lab` was configured for **7-day retention**. This applies to CloudWatch Logs only; it does not delete archived S3 objects.

## 4. Least-privilege IAM user

The `cloudsec-lab-reader` IAM user has permission to list objects and download objects from one designated lab bucket, but is not granted account-wide bucket listing (`s3:ListAllMyBuckets`).

Policy template (replace the placeholder before using it):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListOnlyTheLabBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::REPLACE_WITH_LAB_BUCKET"
    },
    {
      "Sid": "ReadObjectsOnlyInTheLabBucket",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::REPLACE_WITH_LAB_BUCKET/*"
    }
  ]
}
```

The following commands were used or are representative verification steps. The named profile must already be configured in the CLI environment:

```bash
aws sts get-caller-identity --profile cloudsec-lab-reader
aws s3api list-objects-v2 --bucket REPLACE_WITH_LAB_BUCKET --profile cloudsec-lab-reader
aws s3api get-object --bucket REPLACE_WITH_LAB_BUCKET --key test.txt --profile cloudsec-lab-reader test-download.txt
aws s3api list-buckets --profile cloudsec-lab-reader
```

The last command is expected to return `AccessDenied` for `s3:ListAllMyBuckets`. That expected denial is the least-privilege check; do not add the missing permission just to make the command succeed.

## 5. Metric filters and alarms

### Unauthorized API activity

- Filter: `UnauthorizedApiCallsFilter`
- Pattern:

```text
{($.errorCode="*UnauthorizedOperation") || ($.errorCode="AccessDenied*")}
```

- Namespace: `CloudSecLab`
- Metric: `UnauthorizedApiCalls`
- Alarm: `UnauthorizedApiCallsAlarm`
- Statistic: Sum; period: 5 minutes; threshold: `>= 1` datapoint.

### Failed console sign-ins

- Filter: `ConsoleLoginFailuresFilter`
- Pattern:

```text
{ ($.eventSource = "signin.amazonaws.com") && ($.eventName = "ConsoleLogin") && ($.responseElements.ConsoleLogin = "Failure") }
```

- Namespace: `CloudSecLab`
- Metric: `ConsoleLoginFailures`
- Alarm: `ConsoleLoginFailuresAlarm`
- Statistic: Sum; period: 5 minutes; threshold: `>= 3` datapoints.

A configured filter or alarm is not proof of detection. Confirm that a real event matches the filter and that the metric drives an alarm transition before marking that detector as end-to-end tested.

## 6. SNS email notifications

The topic `cloudsec-lab-alerts` has a confirmed email subscription and is attached to both alarms. Keep the recipient's email address out of public documentation and screenshots.

The unauthorized API alarm was triggered by a denied API call and an email was received. The ConsoleLogin alarm action was tested by manually setting the alarm state to `ALARM`; this verifies alarm action → SNS → email delivery, not the real failed-sign-in event-to-filter path.

## References

- [CloudTrail event history](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events.html)
- [AWS Console sign-in events](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-aws-console-sign-in-events.html)
- [CloudWatch Logs metric filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringLogData.html)
