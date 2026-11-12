# IAM permissions

The plugin itself calls no AWS API, so it needs no permissions of its own.

## Permissions

| Action | Resource | Why |
| --- | --- | --- |
| None | — | The connection tests on the "Status" tab for S3, SES and SQS are added by those plugins and use the permissions on their IAM pages: [S3](https://redmine-kit.github.io/redmine_aws_s3/iam.html), [SES](https://redmine-kit.github.io/redmine_aws_ses/iam.html), [SQS](https://redmine-kit.github.io/redmine_aws_sqs/iam.html) |

## Example policy

None.

## Resource-based policies

None.

## Not checked yet

Nothing.
