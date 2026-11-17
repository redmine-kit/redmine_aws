# 導入

Redmine AWS を使う Redmine に必要なもの (インストール、設定、AWS リソース、IAM 権限、ネットワーク) です。Redmine AWS のプラグインはどれもこのプラグインを必要とするので、それらといっしょにインストールします。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて用意します。このページは、手作業で用意するときや、Serverless が作成するものを確認するときのためのものです。

<a id="requirements"></a>

## 動作環境

- Redmine 7.0 以降。プラグインはデータベースに依存しません。テストは PostgreSQL 16 で実行します。
- どのサーバーでも動きます。AWS Lambda、EC2、ECS、それ以外の環境。

<a id="installation"></a>

## インストール

1. プラグインを Redmine 7.0 の `plugins/redmine_aws` に置きます。下の gem か、このリポジトリのチェックアウトです。プラグイン自身が使う gem はないので、このプラグインのための `Gemfile.local` への追加は不要です。チェックアウトの場合、`boot/` のファイルを持つプラグイン (Redmine AWS Lambda、SES、SQS、SSM) はパスで `Gemfile.local` に追加し、そのときは `redmine_aws` もパスで追加します。いくつのプラグインを追加しても、`redmine_aws` の行は 1 つだけです (`gem 'redmine_aws', path: 'plugins/redmine_aws', require: false`。書く行は各プラグインの導入のページにあります)。
2. このプラグインを使う Redmine AWS のプラグインを、このプラグインと同じ `plugins/` にインストールします。Redmine はプラグインをアルファベット順に読み込むので、`redmine_aws` が先になります。各プラグインは、このプラグインがあることを確認します (`requires_redmine_plugin :redmine_aws`)。
3. migration は不要です。

<a id="gem"></a>

### gem

バージョンのタグ (`v*`) ごとに、プラグインを gem として GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`) に公開します (`.github/workflows/gem.yml`)。gem には、実行に必要なファイル (`init.rb`、`boot/`、`lib/`、`app/`、`assets/`、`config/`、`help/`、`LICENSE`) と `test/support/` が入ります。プラグインの `Gemfile` は入れません。ほかの Redmine AWS のプラグインの gem がこの gem に依存するので、Bundler がいっしょにインストールします。Redmine は `plugins/` のプラグインだけを読み込むので、インストールした gem をそこにリンクします。

```sh
ln -s "$(bundle info --path redmine_aws)" plugins/redmine_aws
```

GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` の権限を持つ GitHub のトークンが必要です (`Gemfile.local` に書く行は、各プラグインの導入のページにあります)。

<a id="configuration"></a>

## 設定

プラグイン自身の設定はありません。各プラグインの AWS クライアントは、AWS SDK と同じように、認証情報、リージョン、エンドポイントを読み込みます。

| キー | 説明 | パラメーター |
| --- | --- | --- |
| `AWS_REGION` | AWS クライアントのリージョン。プラグインが自分のリージョンを指定する場合を除く | Lambda が設定する。それ以外では `AWS_REGION` か `AWS_DEFAULT_REGION` |

起動時に SSM Parameter Store から設定とシークレットを読み込むには、[Redmine AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/ja/) を使います。これをインストールすると、「ステータス」のタブに、読み込んだパラメーターの名前が表示されます。

<a id="aws-resources"></a>

## AWS リソース

ありません。

<a id="iam-permissions"></a>

## IAM 権限

プラグインに必要な権限とポリシーの例は、[iam.md](iam.md) にあります。

<a id="network"></a>

## ネットワーク

| 送信先 | API | インターネットに接続できない VPC では |
| --- | --- | --- |
| データベース | PostgreSQL (「ステータス」のタブのデータベースの確認) | サーバーからデータベースのポートへのセキュリティグループのルール |

<a id="tests"></a>

## テスト

テストは `test/` にあり、Redmine の標準の仕組みで、Docker の Redmine 7.0.3 と PostgreSQL 16 で実行します。`bin/test` は、プラグインのテストのあと、管理メニューとプラグインに関係する Redmine 本体のテストを実行します。`bin/test --redmine` は、プラグインをインストールした状態で Redmine 本体のすべてのテストを実行します。CI はこちらを使い、静的チェックとテストを Ruby 3.2 と 4.0 で実行します。ローカルでは、`TEST_RUBY=3.2 bin/test` (または `bin/lint`) で Ruby 3.2 で実行します。

`COVERAGE=1` を付けると、プラグインのテストは、プラグイン自身のファイルのカバレッジ (SimpleCov。Cobertura の XML の `coverage/coverage.xml`) も出力し、1 プロセスで実行します。CI は Ruby 4.0 でこれを有効にし、レポートを `plugin` フラグで [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws) に送信します。送信の認証は OIDC (`id-token: write`) なので、トークンをシークレットに保存しません。Codecov のステータスは参考情報で、コミットや Pull Request を失敗にしません (`codecov.yml`)。

`bin/test-gem` は gem を確認します。チェックアウトから gem をビルドし、[gem](#gem) のとおりにインストールして `plugins/` にリンクし、すべてのファイルを読み込んで Redmine を起動します (`zeitwerk:check` と、起動時にすべてを読み込む production 環境)。CI もこれを実行するので、gem にないファイルがあれば、ほかのプラグインや Serverless がインストールする前に失敗します。

```sh
bin/test            # プラグインのテストと、関係する Redmine のテスト
bin/test --redmine  # Redmine のすべてのテストも実行する
COVERAGE=1 bin/test # カバレッジを coverage/coverage.xml に出力する
bin/test-gem        # gem をビルド・インストールし、plugins/ にリンクして起動する
bin/lint            # RuboCop
bin/screenshots     # admin.md のスクリーンショット
bin/services --down # PostgreSQL を停止する
```

ほかのプラグインのテストは、このプラグインを隣のチェックアウト (`../redmine_aws`、または `REDMINE_AWS_DIR` のディレクトリ) から読み込みます ([api.md](api.md#tests-of-the-plugins))。

<a id="to-verify"></a>

## 未確認の事項

ありません。
