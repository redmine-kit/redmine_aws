# Redmine Kit AWS

Redmine Kit AWS (`redmine_kit_aws`) is the Redmine plugin that the Redmine Kit AWS plugins share. It puts their administration pages under one "AWS" item of Redmine's administration menu, shows the "Status" tab with the connection test, and holds the shared settings of the AWS clients. It works on any server, on AWS Lambda or not. It does not modify Redmine's own files and uses only Redmine's standard extension mechanisms. The plugin is in early development.

- [Setup](setup.md): requirements, installation, configuration, AWS resources, network, tests
- [IAM permissions](iam.md): permissions, example policy, resource-based policies
- [Administration pages](admin.md): the AWS menu, the Status tab
- [Plugin API](api.md): what the other plugins use: tabs, connection checks, the Status tab, AWS clients, test support

## Features

| Feature | Contents | Enabled when | Page |
| --- | --- | --- | --- |
| The AWS menu | One "AWS" item in Redmine's administration menu, whose page has a tab for each installed Redmine Kit AWS plugin | Administrators | [admin.md](admin.md#the-aws-menu) |
| Status | The versions of Redmine and of the Redmine Kit AWS plugins, the settings read from SSM Parameter Store, values that the other plugins add, and the connection test of the database and the AWS services | Administrators | [admin.md](admin.md#status) |
| AWS clients | The region and the options that every plugin's AWS clients get, which tests use to send every request to AWS Emulator (LocalStack or moto only where a plugin's testing docs say so) or, for errors and account states, to SDK stubs | Always (empty unless set) | [api.md](api.md#aws-clients) |

Every Redmine Kit AWS plugin (`redmine_kit_aws_*`) requires Redmine Kit AWS, without exception: each lists it in `config/dependencies.yml` (`requires`), so Redmine stops at boot without it and names it, and each gem depends on the `redmine_kit_aws` gem, so installing a plugin's gem installs it too ([setup.md](setup.md#installation)). The plugins:

| Plugin | Contents |
| --- | --- |
| [Redmine Kit AWS Lambda](https://redmine-kit.github.io/redmine_aws_lambda/) | Running Redmine on AWS Lambda: Lambda Web Adapter's `/events`, the forwarded host, Redmine settings that cannot work on Lambda |
| [Redmine Kit AWS S3](https://redmine-kit.github.io/redmine_aws_s3/) | Attachments in S3: uploads and downloads through CloudFront with signed URLs, the `/tmp` cache |
| [Redmine Kit AWS SES](https://redmine-kit.github.io/redmine_aws_ses/) | Email through SES: retries of sending by error type, receiving and importing, addresses per project |
| [Redmine Kit AWS SQS](https://redmine-kit.github.io/redmine_aws_sqs/) | Jobs on SQS: the settings of `aws-activejob-sqs`, job failure records, resending |
| [Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/) | Settings and secrets from SSM Parameter Store, read before Rails starts; the "Status" tab shows the names of the variables it set |
| [Redmine Kit AWS Cost Explorer](https://redmine-kit.github.io/redmine_aws_costexplorer/) | The AWS account's costs from Cost Explorer |

## Code layout

The registry of the tabs and connection checks is `RedmineKit::Aws::Admin` (`lib/redmine_kit/aws/admin.rb`), the page behind the menu item `AwsAdminController`, the Status tab `AwsStatusController` with `RedmineKit::Aws::Status`, and the settings of the AWS clients `RedmineKit::Aws` (`lib/redmine_kit/aws.rb`). Redmine loads `lib/` and `app/`, and `init.rb` registers the Status tab and the database check. The new UI's tab is `config/kit_ui.yml` and the module built from `frontend/` (`npm run build` writes `assets/javascripts/kit/aws.js` and `assets/stylesheets/kit/aws.css`, which are committed; `npm run check` type-checks, tests and builds it and its Storybook). `test/support/redmine_kit/aws/` holds the test helpers that the other plugins' tests load. The other Redmine Kit AWS plugins put their code in the same namespace (`RedmineKit::Aws::Lambda`, `RedmineKit::Aws::S3`, …; [api.md](api.md#namespace-and-files)).

The plugin calls no AWS API itself, so it needs no AWS SDK gem; each plugin that calls AWS has its own. It adds no database tables, so there are no migrations to run. The code has tests written with Redmine's standard mechanism ([setup.md](setup.md#tests)).

### Tests

| Target | What is checked |
| --- | --- |
| The AWS menu | One menu item, also when more tabs are registered; it opens the first tab; only administrators |
| Status | The versions; the names of the variables that Redmine Kit AWS SSM set; the sections that plugins add, in order (no rows, left out); no secrets on the page; the database check and a failing check; only administrators |
| Status in the new UI | With Redmine Kit UI: the manifest it takes and the screen listed to administrators only; the tab's JSON (the sections, the names only, the connection test, a failing check's class of error) for a kit request with the CSRF token, refused without it, to other users and without the kit header. The module's components (`frontend/`, `npm test`): the sections in order, "No data to display", Test and its results, the error state and the skeleton |
| AWS clients | The region from `AWS_REGION` and `AWS_DEFAULT_REGION`; the order of the options; the test helpers set and restore the options and the environment |
| Code loading | In new processes, with a plugin whose files are named as the plugins name theirs (`ses.rb` for `RedmineKit::Aws::Ses`, …): `zeitwerk:check` passes and the modules load, also with the `RedmineKit::Aws` namespace defined before Rails as a boot file of another plugin does |

## Sponsors

<Sponsors ids="keyselect"><a href="https://www.keyselect.co.jp/">KEY SELECT</a></Sponsors>

## License

Redmine Kit AWS is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](../LICENSE). An unofficial Redmine plugin.
