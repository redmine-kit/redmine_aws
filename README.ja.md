# Redmine Kit AWS

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_aws/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_aws/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_aws?label=Coverage)](https://codecov.io/gh/redmine-kit/redmine_aws)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_aws?label=License)](LICENSE)

Redmine Kit AWS のプラグインが共通で使う Redmine のプラグインです。Redmine の管理メニューの「AWS」とプラグインごとのタブ、バージョンとデータベースや AWS のサービスへの接続テストを表示する「ステータス」のタブ、AWS クライアントの共通設定を持ちます。どのサーバーでも動きます。Redmine Kit AWS のプラグインはどれもこのプラグインを必要とし、その gem がこのプラグインの gem に依存するので、いっしょにインストールされます。[Redmine Kit AWS Lambda](https://github.com/redmine-kit/redmine_aws_lambda)、[Redmine Kit AWS S3](https://github.com/redmine-kit/redmine_aws_s3)、[Redmine Kit AWS SES](https://github.com/redmine-kit/redmine_aws_ses)、[Redmine Kit AWS SQS](https://github.com/redmine-kit/redmine_aws_sqs)、[Redmine Kit AWS SSM](https://github.com/redmine-kit/redmine_aws_ssm)、[Redmine Kit AWS Cost Explorer](https://github.com/redmine-kit/redmine_aws_costexplorer) です。[Serverless](https://github.com/redmine-kit/serverless) は、これらを AWS Lambda にインストールします。

[English](README.md)

> **状態:** 開発の初期です。実装し、Redmine 7.0.3 でテストしています。

<a id="documentation"></a>

## ドキュメント

- Web サイト: https://redmine-kit.github.io/redmine_aws/ja/ (English: https://redmine-kit.github.io/redmine_aws/)
- Markdown: [docs/ja/README.md](docs/ja/README.md) (English: [docs/README.md](docs/README.md))。[導入](docs/ja/setup.md)、[IAM 権限](docs/ja/iam.md)、[管理画面](docs/ja/admin.md)、[プラグインの API](docs/ja/api.md) があります。

<a id="sponsors"></a>

## スポンサー

<a href="https://www.keyselect.co.jp/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keyselect-logo-dark.svg">
    <img alt="KEY SELECT" src=".github/assets/keyselect-logo.svg" width="136" height="29">
  </picture>
</a>

<a id="license"></a>

## ライセンス

Redmine Kit AWS は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](LICENSE) を参照してください。Redmine の非公式のプラグインです。
