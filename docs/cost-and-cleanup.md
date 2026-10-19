# Cost review and cleanup

## Cost review

The AWS bill was not verified as part of the recorded testing. Before leaving the lab running, open [AWS Billing and Cost Management](https://console.aws.amazon.com/costmanagement/home/) and review Bills, Cost Explorer (if available), and any Free Tier or usage dashboard available to your account.

Potential charge areas include:
- CloudTrail management-event copies or additional data-event configurations, depending on the trail design and usage.
- S3 storage and requests for archived CloudTrail logs.
- CloudWatch Logs ingestion and storage, metric filters, custom metrics, and alarms.
- SNS notifications beyond any applicable free allowance.

Actual charges depend on account eligibility, configuration, Region, and usage. Do not assume the lab is free because it is small.

## Security review items

- CloudWatch Logs retention is 7 days; this does not set S3 object retention.
- Explicit SSE-KMS encryption for the CloudTrail S3 destination was not enabled at the time of the recorded review. Check the bucket's actual default encryption and consider a suitable encryption/key-management approach.
- Confirm S3 Block Public Access is enabled and bucket policies limit access to required principals.
- Keep credentials and unredacted CloudTrail logs out of GitHub.
- Do not put AWS account identifiers, personal email addresses, or sensitive source details in public screenshots unless necessary and deliberately redacted.

## Cleanup options

Only delete resources created specifically for this lab. Preserve logs and screenshots needed for project evidence before removing storage.

1. Disable or delete the CloudWatch alarms `UnauthorizedApiCallsAlarm` and `ConsoleLoginFailuresAlarm` if monitoring is no longer needed.
2. Delete the metric filters from `/aws/cloudtrail/security-lab` if no longer required.
3. Unsubscribe the test email or delete the `cloudsec-lab-alerts` SNS topic when finished.
4. If ending the lab, stop or delete `Cloudsec-lab-trail` after preserving required logs. Review all trails before changing shared logging resources.
5. Delete `/aws/cloudtrail/security-lab` only after deciding that its events are no longer needed.
6. Remove the lab IAM user's test permissions/user only after checking it is not used by another workflow.
7. Delete the S3 log archive only if you intentionally no longer need the retained evidence. Emptying and deleting an S3 bucket is destructive; verify the bucket name and contents first.
8. Recheck Billing and Cost Management after cleanup to confirm no unexpected resources remain.

Never delete or modify unrelated account resources during cleanup.
