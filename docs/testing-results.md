# Testing Results

**Test window:** 18–20 October 2026  
**Environment:** AWS account lab in `ap-southeast-2` (Sydney)

## Executive summary

The lab successfully demonstrated CloudTrail event collection, restricted S3 access, detection of an unauthorized API request, and email notification through CloudWatch alarms and SNS. The failed-console-login alarm is configured, but its real event-to-metric-to-alarm path remains unverified.

## Test matrix

| ID | Test | Expected result | Observed result | Status |
|---|---|---|---|---|
| T-01 | CloudTrail to CloudWatch Logs delivery | Trail events appear in the configured log group | Four log streams were visible; the newest listed event time during the check was 18 Oct 2026 07:24:13 UTC | **Pass** |
| T-02 | Restricted S3 object listing | The reader can list objects in its allowed bucket | Object listing succeeded | **Pass** |
| T-03 | Restricted S3 object retrieval | The reader can download an object from its allowed bucket | `test.txt` was downloaded successfully | **Pass** |
| T-04 | Account-wide bucket listing by restricted identity | Request is denied because `s3:ListAllMyBuckets` is not granted | `AccessDenied` observed and recorded in CloudTrail | **Pass** |
| T-05 | Unauthorized API detection | Denied request increments the metric and triggers the alarm | `UnauthorizedApiCallsAlarm` entered `ALARM`, email was received, and the alarm later returned to `OK` | **Pass — end to end** |
| T-06 | SNS email subscription | Alarm notification reaches the confirmed recipient | Notification email received | **Pass** |
| T-07 | ConsoleLogin alarm notification action | An alarm in `ALARM` state invokes SNS and sends email | Manual `set-alarm-state` test generated an email | **Pass — action path only** |
| T-08 | Real failed-console-login event matching | Real failed sign-in creates a matching CloudTrail record and metric | No `ConsoleLogin` events were returned in the investigated Sydney Event history query | **Not verified** |
| T-09 | Three-failure alarm threshold | Three matching metric units within the evaluation period trigger the alarm | A manual state change does not test the threshold; real matching event sequence was not observed | **Not verified** |
| T-10 | Billing and credit review | Current account billing state is documented | On 20 Oct 2026: $0.00 amount due, $99.99 remaining credits, $0.01 month-to-date usage; Free plan end date shown as 14 Apr 2027 | **Reviewed** |

## Unauthorized API detection

The negative-permission test used the restricted CLI profile to request account-wide bucket listing. The request was denied because the identity did not have `s3:ListAllMyBuckets`. The corresponding event was visible in CloudTrail, and the unauthorized API alarm entered `ALARM`. An SNS email was received, and the alarm later returned to `OK` after the metric stopped breaching the threshold.

This establishes the following tested path:

```text
Denied API request → CloudTrail → CloudWatch Logs
→ Metric filter → CloudWatch alarm → SNS → Email
```

## Console login alarm: verification boundary

The configured filter matches records where the event source is `signin.amazonaws.com`, the event name is `ConsoleLogin`, and `responseElements.ConsoleLogin` is `Failure`. Event History in the Sydney Region returned no `ConsoleLogin` records for the investigated time range.

The following manual state change was performed:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "ConsoleLoginFailuresAlarm" \
  --state-value ALARM \
  --state-reason "Manual test of failed console login alarm notification" \
  --region ap-southeast-2
```

An email was received. This confirms the alarm action-to-SNS-to-email path. It does **not** demonstrate that a real failed sign-in matched the metric filter, nor that three genuine failures crossed the configured threshold.

Consequently, this detector is reported as **configured, with notification action tested, but not end-to-end verified**. The absence of events in the investigated view is not proof that all Google- or federated sign-in failures are invisible to CloudTrail; the recorded authentication path and relevant event location would need to be established before making that conclusion.

## Overall assessment

The primary unauthorized API alert workflow is end-to-end verified. Least-privilege access behavior and SNS delivery are demonstrated. The console-login detector is present as a configured secondary rule, with its real event-matching behavior remaining an explicit validation limitation.

