# Testing results

Test observations collected during the lab on 18–19 October 2026. These notes separate observed behavior from tests that remain outstanding.

## Summary

| Test | Status | Evidence / notes |
|---|---|---|
| CloudTrail to CloudWatch Logs delivery | Pass | Four log streams were visible; newest listed event time was 2026-10-18 07:24:13 UTC. |
| Restricted S3 list/read operations | Pass | `cloudsec-lab-reader` listed objects in its allowed bucket and downloaded `test.txt`. |
| Least-privilege denial | Pass | `list-buckets` was denied because `s3:ListAllMyBuckets` was not granted. |
| Unauthorized API-call filter/alarm | Pass | Denied request produced an alert; `UnauthorizedApiCallsAlarm` entered `ALARM`, an email arrived, and the alarm later returned to `OK`. |
| SNS email subscription | Pass | An alert email was received; subscription was confirmed. |
| Manual test of failed-login alarm action | Pass — notification path only | `aws cloudwatch set-alarm-state` set `ConsoleLoginFailuresAlarm` to `ALARM`; an email arrived. |
| Real failed-console-login event matching | Pending | Event History in `ap-southeast-2` returned no `ConsoleLogin` results for the selected time range. |
| Actual three-failure alarm threshold | Pending | A manual alarm-state change does not establish that three real sign-in failures generated the metric. |
| AWS billing review | Pending | Review actual usage and charges in Billing and Cost Management. |

## Unauthorized API test

The following command was run using the restricted CLI profile:

```bash
aws s3api list-buckets --profile cloudsec-lab-reader
```

Expected and observed behavior: access was denied because the user lacked `s3:ListAllMyBuckets`. This was a safe negative-permission test; do not add the missing permission.

The `UnauthorizedApiCallsAlarm` changed to `ALARM` around 18 October 2026 07:41 UTC, an alert email was received, and the alarm later returned to `OK` after the metric stopped breaching its threshold.

## Failed console sign-in alarm

The filter is configured to match CloudTrail records with event source `signin.amazonaws.com`, event name `ConsoleLogin`, and `responseElements.ConsoleLogin = Failure`. The alarm threshold is at least three metric units in a five-minute evaluation period.

CloudTrail Event history was searched in the Sydney Region with event name `ConsoleLogin` for the selected period and returned no matches. The alarm action was then tested manually:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "ConsoleLoginFailuresAlarm" \
  --state-value ALARM \
  --state-reason "Manual test of failed console login alarm notification" \
  --region ap-southeast-2
```

An email was received. This verifies alarm action → SNS → email delivery. It **does not** verify that the metric filter matches real failed sign-in records or that three actual failures trigger the alarm.

### Recommended follow-up

1. Search appropriate CloudTrail Regions and the CloudWatch Logs group for `eventSource = signin.amazonaws.com` and `eventName = ConsoleLogin`.
2. If records are found, inspect `responseElements.ConsoleLogin` and validate the pattern against the actual event.
3. Only mark the real failed-login detector as end-to-end verified after real matching events produce the metric, the threshold is crossed, and the notification is received.

Do not deliberately enter incorrect credentials several times on a production/root account. Use an approved test identity only if a real sign-in test is needed and account lockout/identity-provider risks have been assessed.
