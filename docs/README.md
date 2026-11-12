# Redmine AWS

Redmine AWS (`redmine_aws`) is the Redmine plugin that the Redmine AWS plugins share. It puts their administration pages under one "AWS" item of Redmine's administration menu, shows the "Status" tab with the connection test, and holds the shared settings of the AWS clients. It works on any server, on AWS Lambda or not. It does not modify Redmine's own files and uses only Redmine's standard extension mechanisms. The plugin is in early development.

- [Setup](setup.md): requirements, installation, configuration, AWS resources, network, tests
- [IAM permissions](iam.md): permissions, example policy, resource-based policies
- [Administration pages](admin.md): the AWS menu, the Status tab
- [Plugin API](api.md): what the other plugins use: tabs, connection checks, the Status tab, AWS clients, test support

## Features

| Feature | Contents | Enabled when | Page |
| --- | --- | --- | --- |
| The AWS menu | One "AWS" item in Redmine's administration menu, whose page has a tab for each installed Redmine AWS plugin | Administrators | [admin.md](admin.md#the-aws-menu) |
| Status | The versions of Redmine and of the Redmine AWS plugins, the settings read from SSM Parameter Store, values that the other plugins add, and the connection test of the database and the AWS services | Administrators | [admin.md](admin.md#status) |
| AWS clients | The region and the options that every plugin's AWS clients get, which tests use to send every request to AWS Emulator (LocalStack or moto only where a plugin's testing docs say so) or, for errors and account states, to SDK stubs | Always (empty unless set) | [api.md](api.md#aws-clients) |

Every Redmine AWS plugin (`redmine_aws_*`) requires Redmine AWS, without exception: each declares it in `init.rb` (`requires_redmine_plugin :redmine_aws`), so Redmine refuses to start without it, and each gem depends on the `redmine_aws` gem, so installing a plugin's gem installs it too ([setup.md](setup.md#installation)). The plugins:

| Plugin | Contents |
| --- | --- |
| [Redmine AWS Lambda](https://redmine-kit.github.io/redmine_aws_lambda/) | Running Redmine on AWS Lambda: Lambda Web Adapter's `/events`, the forwarded host, Redmine settings that cannot work on Lambda |
| [Redmine AWS S3](https://redmine-kit.github.io/redmine_aws_s3/) | Attachments in S3: uploads and downloads through CloudFront with signed URLs, the `/tmp` cache |
| [Redmine AWS SES](https://redmine-kit.github.io/redmine_aws_ses/) | Email through SES: retries of sending by error type, receiving and importing, addresses per project |
| [Redmine AWS SQS](https://redmine-kit.github.io/redmine_aws_sqs/) | Jobs on SQS: the settings of `aws-activejob-sqs`, job failure records, resending |
| [Redmine AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/) | Settings and secrets from SSM Parameter Store, read before Rails starts; the "Status" tab shows the names of the variables it set |
| [Redmine AWS Cost Explorer](https://redmine-kit.github.io/redmine_aws_costexplorer/) | The AWS account's costs from Cost Explorer |

## Code layout

The registry of the tabs and connection checks is `RedmineAws::Admin` (`lib/redmine_aws/admin.rb`), the page behind the menu item `AwsAdminController`, the Status tab `AwsStatusController` with `RedmineAws::Status`, and the settings of the AWS clients `RedmineAws` (`lib/redmine_aws.rb`). Redmine loads `lib/` and `app/`, and `init.rb` registers the Status tab and the database check. `boot/redmine_aws/inflections.rb` gives Rails' code loaders the module names of the plugins' files ([api.md](api.md#namespace-and-files)). `test/support/redmine_aws/` holds the test helpers that the other plugins' tests load. The other Redmine AWS plugins put their code in the same namespace (`RedmineAws::Lambda`, `RedmineAws::S3`, …; [api.md](api.md#namespace-and-files)).

The plugin calls no AWS API itself, so it needs no AWS SDK gem; each plugin that calls AWS has its own. It adds no database tables, so there are no migrations to run. The code has tests written with Redmine's standard mechanism ([setup.md](setup.md#tests)).

### Tests

| Target | What is checked |
| --- | --- |
| The AWS menu | One menu item, also when more tabs are registered; it opens the first tab; only administrators |
| Status | The versions; the names of the variables that Redmine AWS SSM set; the sections that plugins add, in order; no secrets on the page; the database check and a failing check; only administrators |
| AWS clients | The region from `AWS_REGION` and `AWS_DEFAULT_REGION`; the order of the options; the test helpers set and restore the options and the environment |
| Code loading | In new processes, with a plugin whose files are named as the plugins name theirs (`ses.rb` for `RedmineAws::SES`, …): `zeitwerk:check` passes and the modules load, also with the `RedmineAws` namespace defined before Rails as a boot file of another plugin does |

## Sponsors

<Sponsors ids="keyselect"><a href="https://www.keyselect.co.jp/">KEY SELECT</a></Sponsors>

## License

Redmine AWS is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](../LICENSE). An unofficial Redmine plugin.
