# AWS administration

Redmine Kit AWS adds **AWS** to the **Administration** menu: one page with a tab for each installed Redmine Kit AWS plugin. **AWS** opens the first tab. Only administrators can open the page.

| Tab | Added by |
| --- | --- |
| **Status** | Redmine Kit AWS |
| **Jobs** | Redmine Kit AWS SQS |
| **Email sending**, **Email receiving** | Redmine Kit AWS SES |
| **S3** | Redmine Kit AWS S3 |
| **Cost Explorer** | Redmine Kit AWS Cost Explorer |

The plugins' settings are on their tabs. In **Administration** › **Plugins**, only Redmine Kit AWS S3 has **Configure**, which opens its **S3** tab.

## Status

The **Status** tab shows values; it changes nothing, and opening it calls no AWS API.

- **Versions**: Redmine, Ruby, Rails and each installed Redmine Kit AWS plugin.
- **Parameter Store**: with Redmine Kit AWS SSM, the names of the environment variables read from AWS Systems Manager Parameter Store when Redmine started. The values are never shown.
- The values of other plugins: on AWS Lambda, Redmine Kit AWS Lambda adds **Lambda function** before the versions and **Read-only settings** after them.

## Connection test

**Test** checks once, in the request, whether Redmine reaches the database and the AWS services of the installed plugins:

- **Database**: a new connection to the configured database, shown with its version (for example "PostgreSQL 16.4").
- **S3**, **SES**, **SQS**: one light call each, added by Redmine Kit AWS S3 (when its bucket is set), Redmine Kit AWS SES and Redmine Kit AWS SQS.

Each row shows **OK** or **Failed**, the details and the response time in milliseconds. A failed check shows only the class of the error (for example `Aws::S3::Errors::Forbidden`); the error's message is written to Redmine's log. Run the test after changing IAM permissions, the network or the settings in Parameter Store.
