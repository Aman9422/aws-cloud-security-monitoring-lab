# Cost and Security Review

**Review date:** 20 October 2026

## Billing snapshot

| Billing indicator | Observed value |
|---|---:|
| AWS plan | Free |
| Amount due | $0.00 |
| Remaining credits | $99.99 |
| Month-to-date usage shown by the project dashboard | $0.01 |
| Free plan end date shown in the account dashboard | 14 April 2027 |
| Cost coverage message | Dashboard reported that usage was covered by available AWS Free Tier credits |

The displayed service-level cost breakdown showed Amazon S3 at $0.01 and the other listed services at $0.00. The detailed view did not establish which individual bucket or operation accounted for the S3 amount.

These values are a point-in-time observation from the account dashboard, not a guarantee of future zero cost. Charges and credit eligibility can vary with configuration, usage, Region, and plan terms.

## Cost-bearing components

| Component | Potential cost driver in this design |
|---|---|
| Amazon S3 | CloudTrail archive storage and requests |
| CloudWatch Logs | Log ingestion and stored events |
| CloudWatch metrics and alarms | Custom metrics, metric filters, alarms, and evaluation |
| AWS CloudTrail | Additional event types or data-event configurations beyond applicable included usage |
| Amazon SNS | Notification delivery beyond any applicable allowance |
| AWS KMS | Key usage if customer-managed KMS encryption is enabled |

Actual account billing remains authoritative for this project. The recorded dashboard showed a small usage amount covered by available credits and no amount due.

## Security observations

- **Audit logging:** A multi-region CloudTrail trail delivers logs to S3 and the CloudWatch Logs group `/aws/cloudtrail/security-lab`.
- **CloudWatch retention:** The log group is configured for 7 days. This does not set retention or deletion for objects in the S3 archive.
- **Archive encryption:** Explicit SSE-KMS configuration for the CloudTrail S3 destination had not been enabled at the time of the recorded review. The bucket's default encryption configuration should be verified separately before any production use.
- **Access control:** The S3 reader test demonstrated permitted object listing and retrieval within a designated bucket, and denial of account-wide bucket listing.
- **Detection coverage:** Unauthorized API detection was end-to-end verified. The ConsoleLogin rule's email action was tested, but real failed-login event matching remains unverified.
- **Public repository hygiene:** The public documentation omits account-specific bucket identifiers and alert email addresses. Credentials, access keys, secret keys, session tokens, and raw sensitive logs are not suitable for repository storage.

## Resource lifecycle considerations

The lab includes a CloudTrail trail, an S3 log archive, a CloudWatch log group, metric filters, alarms, an SNS topic, and a restricted IAM test identity. Their continued operation and retained data can have cost and security implications. Logs and screenshots may also be required as portfolio evidence, so deletion of evidence-bearing resources would change the documented state and may remove useful audit records.

The project is an educational monitoring lab. Production adoption would require a defined retention policy, verified encryption settings, reviewed access policies, and ongoing cost monitoring.
