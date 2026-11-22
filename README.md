# Redmine Kit AWS

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_aws/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_aws/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_aws?label=Coverage)](https://codecov.io/gh/redmine-kit/redmine_aws)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_aws?label=License)](LICENSE)

The Redmine plugin that the Redmine Kit AWS plugins share: the "AWS" item of Redmine's administration menu with a tab per plugin, the "Status" tab with the versions and a connection test of the database and the AWS services, and the shared settings of the AWS clients. It works on any server. Every Redmine Kit AWS plugin requires it, and their gems depend on its gem, which installs it with them: [Redmine Kit AWS Lambda](https://github.com/redmine-kit/redmine_aws_lambda), [Redmine Kit AWS S3](https://github.com/redmine-kit/redmine_aws_s3), [Redmine Kit AWS SES](https://github.com/redmine-kit/redmine_aws_ses), [Redmine Kit AWS SQS](https://github.com/redmine-kit/redmine_aws_sqs), [Redmine Kit AWS SSM](https://github.com/redmine-kit/redmine_aws_ssm) and [Redmine Kit AWS Cost Explorer](https://github.com/redmine-kit/redmine_aws_costexplorer); [Serverless](https://github.com/redmine-kit/serverless) installs them on AWS Lambda.

[日本語](README.ja.md)

> **Status:** early development. It is implemented and tested on Redmine 7.0.3.

## Documentation

- Website: https://redmine-kit.github.io/redmine_aws/ ([日本語](https://redmine-kit.github.io/redmine_aws/ja/))
- Markdown: [docs/README.md](docs/README.md) ([日本語](docs/ja/README.md)), with [setup](docs/setup.md), [IAM permissions](docs/iam.md), the [administration pages](docs/admin.md) and the [plugin API](docs/api.md)

## Help

With [Redmine Kit Help](https://github.com/redmine-kit/redmine_help) installed, the plugin's help is in `help/`: the topic AWS administration (English and Japanese), on the AWS menu, the Status tab and the connection test. The Status tab opens it from the Help panel (`help/map.yml`). Check it against the installed guide from Redmine's folder:

```sh
bin/rails redmine_kit:help:check PLUGIN=redmine_kit_aws
```

## Sponsors

<a href="https://www.keyselect.co.jp/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keyselect-logo-dark.svg">
    <img alt="KEY SELECT" src=".github/assets/keyselect-logo.svg" width="136" height="29">
  </picture>
</a>

## License

Redmine Kit AWS is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](LICENSE). An unofficial Redmine plugin.
