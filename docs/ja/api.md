# プラグインの API

ほかの Redmine Kit AWS のプラグインが Redmine Kit AWS から使うものです。Redmine Kit AWS のプラグインは、何も使わないプラグインも含めてどれも、`init.rb` と gemspec でこのプラグインを必要とします。

```ruby
# init.rb の Redmine::Plugin.register の中
requires_redmine_plugin :redmine_kit_aws, version_or_higher: '0.1.0'
```

```ruby
# <プラグイン>.gemspec
spec.add_dependency 'redmine_kit_aws', '~> 0.1'
```

Redmine はプラグインをアルファベット順に読み込むので、ほかのプラグインの `init.rb` より前に、`redmine_kit_aws` の `init.rb` が実行されます。

<a id="namespace-and-files"></a>

## 名前空間とファイル

Redmine Kit AWS のプラグインは、どれもコードを名前空間 `RedmineKit::Aws` の下に置きます。名前空間はこのプラグインが `lib/redmine_kit/aws.rb` で定義します。その上の `RedmineKit` は Redmine Kit のすべてのプラグインの名前空間で、どのプラグインのものでもありません。`lib/redmine_kit.rb` を持つプラグインはなく、Redmine のコードローダー (Zeitwerk) が、各プラグインの `lib/redmine_kit/` ディレクトリからモジュールを作ります。Redmine は各プラグインの `lib/` をローダーのルートディレクトリにするからです。各プラグインのテストは、`lib/redmine_kit.rb` があると失敗します。

| プラグイン | モジュール | ファイル |
| --- | --- | --- |
| `redmine_kit_aws_lambda` | `RedmineKit::Aws::Lambda` | `lib/redmine_kit/aws/lambda.rb` (`VERSION` と `setup` を持つモジュール)、`lib/redmine_kit/aws/lambda/*.rb` |
| `redmine_kit_aws_s3` | `RedmineKit::Aws::S3` | `lib/redmine_kit/aws/s3.rb`、`lib/redmine_kit/aws/s3/*.rb` |

ほかのプラグインも同じ規則で、モジュール名はコードローダーがファイル名から付ける既定の名前です。`lib/redmine_kit/aws/ses.rb` の `RedmineKit::Aws::Ses`、`sqs.rb` の `RedmineKit::Aws::Sqs`、`RedmineKit::Aws::Ssm`、`costexplorer.rb` の `RedmineKit::Aws::Costexplorer`、`RedmineKit::Aws::Dsql` で、`lib/redmine_kit/aws/ses/receiver.rb` は `RedmineKit::Aws::Ses::Receiver` です。`RedmineKit` の中では `Aws` は `RedmineKit::Aws` なので、AWS SDK は必ず `::Aws::S3::Client` のように書きます。`app/` のクラスはトップレベルのままです (`AwsS3AdminController`)。このプラグインが `RedmineKit::Aws` の直下に定義する名前 (`VERSION`、`setup`、`client`、`Admin`、`AdminTab`、`Status`、`TestHelper`、`ScreenshotCase` と、このページのほかの名前) は、ほかのプラグインでは定義しません。

[Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/ja/) は例外で、`lib/` を持ちません。Rails が起動する前に Parameter Store を読むためです。Bundler が読み込む `boot/redmine_kit_aws_ssm/loader.rb` が `RedmineKit::Aws::Ssm` (`VERSION`、`Loader`、設定した変数の名前を持つ `RedmineKit::Aws::Ssm.loaded`) を定義し、「ステータス」のタブは、このモジュールがあれば `RedmineKit::Aws::Ssm.loaded` を読みます (`RedmineKit::Aws::Status#loaded_settings`)。

Bundler が Rails より前に読み込む `boot/` のファイルは、gem の名前のまま (`boot/redmine_kit_aws_lambda.rb`) にし、定数はプラグインのモジュールの中に定義します (`RedmineKit::Aws::Lambda::Boot`)。定数の外側のモジュールは、空のまま入れ子で書き (`module RedmineKit`、`module Aws`、`module Lambda`。`RedmineKit` が定義済みでないと使えない `module RedmineKit::Aws` は使いません)、このプラグインが定義するものは定義しません。このときコードローダーは、モジュールがすでにあるので `lib/redmine_kit/aws.rb` とプラグインの `lib/redmine_kit/aws/<プラグイン>.rb` を読み込みません。各プラグインの `init.rb` がそのファイルを読み込みます。

```ruby
# redmine_kit_aws_lambda の init.rb。Redmine::Plugin.register の前
require File.expand_path('lib/redmine_kit/aws/lambda', __dir__) unless defined?(RedmineKit::Aws::Lambda::VERSION)
```

すべてのファイルを読み込めることは `bin/rails zeitwerk:check` で確認します。このプラグインのテストは、上の名前のファイルを持つプラグインを使い、Rails より前に名前空間を定義した場合も含めて実行します。Redmine Kit AWS Lambda のテストは、boot のファイルを読み込んだ状態で実行します。

<a id="tabs-and-connection-checks"></a>

## タブと接続テスト

```ruby
RedmineKit::Aws::Admin.register_tab(:jobs, label: :label_aws_sqs_jobs,
                                      url: { controller: 'aws_sqs_jobs', action: 'index' }, position: 20)
RedmineKit::Aws::Admin.register_check(:sqs, label: :label_aws_sqs_check) { Queue.new.check }
```

| メソッド | 内容 |
| --- | --- |
| `register_tab(name, label:, url:, position:)` | AWS のページのタブ。i18n のキー、ルートのハッシュ、順序 (ステータスは 10)。最初のタブが「AWS」のメニューの項目を追加する |
| `register_check(name, label:) { … }` | ステータスのタブの「テスト」で実行する接続テスト。ブロックは軽い呼び出しを 1 回行い、画面に表示する短いテキストを返す。例外を発生させると、失敗として例外のクラスだけを表示する。ホスト、アカウント、リソースを含むことがあるメッセージは、接続テストの名前といっしょに Redmine のログに記録する |
| `tabs`、`checks`、`run_checks` | 登録したタブ (順序どおり)、確認、すべての確認を実行した結果 |
| `routed?` | `admin/aws` のルートがあるかどうか。あるときだけメニューの項目を表示する |

これらは、プラグインの `init.rb` のセットアップから呼び出します。Redmine は、コードの再読み込みのたびに `init.rb` を実行し直します。タブのルートは `admin/aws/` の下に置きます。`admin/aws` と `admin/aws/status` はこのプラグインのものです。

<a id="tab-controllers-and-views"></a>

## タブのコントローラーとビュー

```ruby
class AwsSqsJobsController < ApplicationController
  include RedmineKit::Aws::AdminTab
end
```

`RedmineKit::Aws::AdminTab` は、Redmine の管理画面のレイアウトを使い、「AWS」のメニューの項目を選択状態にし、システム管理者だけに許可します (`require_admin`)。ビューはタブから始めます。`selected` は `register_tab` に渡した名前です。

```erb
<%= render partial: 'aws_admin/tabs', locals: { selected: 'jobs' } %>
```

<a id="the-status-tab"></a>

## ステータスのタブ

```ruby
RedmineKit::Aws::Admin.register_status_section(:lambda_function, partial: 'aws_lambda/function', position: 10)
```

`register_status_section(name, partial:, position:)` は、ステータスのタブに項目を追加します。ビューのパーシャルを、ローカル変数 `status` (`RedmineKit::Aws::Status`) を渡して、タブ自身の項目 (バージョンは 20、Parameter Store は 30) の間の位置に表示します。接続テストは最後です。`status_sections` は、項目を順序どおりに返します。タブは、ファミリーのプラグインのバージョンを表示します。`redmine_kit_aws` と、ID が `redmine_kit_aws_` で始まるプラグインです (`RedmineKit::Aws::Status.family?`)。

<a id="values"></a>

## 値の表示

```erb
<h3><%= l(:label_aws_lambda_function) %></h3>
<%= render partial: 'aws_admin/values', locals: { rows: [
      { name: l(:field_aws_lambda_function_name), value: name || '-' },
      { name: l(:field_aws_lambda_function_role), value: role || '-', note: 'REDMINE_ROLE' }
    ] } %>
```

`aws_admin/values` は、編集しない値 (バージョン、状態、確認の結果) を、「管理」›「情報」と同じ形で表示します ([Redmine Design Guide: 情報](https://redmine-kit.github.io/design-guide/ja/information.html))。ヘッダー行のない `table.list.values` と、そのあとの `<br />` です。各行はハッシュで、`name` (`td.name`) と、必要に応じて `value` (`td.value`)、`note` (値の下の `em.info`。値の元の環境変数や設定など)、`ok` (`true` か `false`。Redmine のアイコンの `td.tick` と、行のクラス `ok` か `failed`) を持ちます。`css` はテーブルにクラスを追加します (接続テストは `checks`)。部分テンプレートは、ページの表の数にかかわらず、スタイルシート (`assets/stylesheets/aws_values.css`) をページの `header_tags` に 1 回だけ追加します。名前は 1 行のままで、長い値 (digest 付きのイメージ URI など) は、名前を狭めずに、任意の位置で折り返します。Redmine Kit AWS のどのプラグインも、編集しない値は、「ステータス」のタブでも自身のタブでも、これで表示します。

<a id="aws-clients"></a>

## AWS クライアント

```ruby
RedmineKit::Aws.client(::Aws::S3::Client)
RedmineKit::Aws.client(::Aws::CostExplorer::Client, region: 'us-east-1', http_open_timeout: 5, retry_limit: 2)
```

| メソッド | 内容 |
| --- | --- |
| `client(klass, **options)` | SDK のクラスのクライアント。オプションは、弱い順に、`region` のリージョン、ここで渡したオプション、`client_options`。ここで nil を渡したオプションは除き、SDK のデフォルトの解決順序に任せます (SDK は明示的な `credentials: nil` や `region: nil` をそのまま使い、署名できなくなるためです) |
| `region` | `AWS_REGION`、なければ `AWS_DEFAULT_REGION`。どちらもなければ nil |
| `client_options`、`client_options=` | `client` で作成するすべてのクライアントに渡すオプション。設定しなければ空で、SDK はいつもどおり認証情報、リージョン、エンドポイントを読み込む (`AWS_ENDPOINT_URL`、`AWS_ENDPOINT_URL_<SERVICE>`)。テストでは、リクエストを AWS Emulator に送るために設定する (LocalStack と moto は、プラグインのテストの資料が示すところだけ)。ほかの方法で用意できないエラーとアカウントの状態は、SDK のスタブに送る |
| `env_true?(name)` | 環境変数が `true` かどうか。大文字と小文字を区別せず、前後の空白は無視する |

このプラグインは AWS SDK の gem を持ちません。各プラグインが、呼び出すサービスの SDK の gem に依存します。

<a id="compatibility"></a>

## 互換性

プラグインは `redmine_kit_aws ~> 0.1` (0.1 以上 1.0 未満) に依存します。このプラグインが 0.x の間は、新しいマイナーバージョンやパッチバージョンでも、このページに書いたものはプラグインからそのまま使えます。追加はしても、プラグインが使うものを変更したり削除したりはしません。プラグインが動かなくなる変更は 1.0 でだけ行い、プラグインはそのとき新しいメジャーバージョンに依存します。各プラグインの CI は、公開した最新の 0.x のバージョンでもテストします (`test (redmine_kit_aws release)`。[下記](#redmine-kit-aws-in-the-test-image))。

<a id="tests-of-the-plugins"></a>

## プラグインのテスト

<a id="test-helpers"></a>

### テストヘルパー

`test/support/redmine_kit/aws/` は、リポジトリにも gem にも入っています。プラグインの `test/test_helper.rb` は、Redmine のテストヘルパーのあとに、`redmine_kit_aws` をインストールした場所からこれを読み込みます。

```ruby
require File.expand_path('../../../test/test_helper', __dir__)
require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit/aws/test_helper')
```

| `RedmineKit::Aws::TestHelper` | 内容 |
| --- | --- |
| `with_env(values) { … }` | ブロックの間だけ環境変数を設定し (`nil` は削除)、元に戻す |
| `with_aws_client_options(**options) { … }` | ブロックの間だけ、オプションを `RedmineKit::Aws.client_options` にマージする。たとえば AWS Emulator の `endpoint:` |
| `stub_aws_client(klass, **stubs)` | SDK のレスポンスのスタブ (`stub_responses`) を持つクライアント。リージョンは `us-east-1`、認証情報はテスト用。スタブを渡さなければ、どの呼び出しも SDK のスタブデータ (レスポンスの形に沿った仮の値) を返す |
| `TEST_REGION`、`TestHelper.credentials` | テストで使うクライアントのリージョン (`us-east-1`) と認証情報 (`test`/`test`)。AWS Emulator (認証はオフ)、LocalStack、moto はこれを受け付ける |

Redmine のテストヘルパーが読み込む Mocha の下でも、レスポンスのスタブを持つ SDK のクライアントが動くようにします (`RedmineKit::Aws::SdkConfigStubs`)。aws-sdk-core 3.270.0 以降、Mocha の `Object#stubs` がクライアントのオプション `stubs` を隠し、スタブを渡したクライアントの作成やその呼び出しで `ArgumentError` が発生します ([aws/aws-sdk-ruby#3501](https://github.com/aws/aws-sdk-ruby/issues/3501)、2026-11-19 時点で未解決)。SDK のリリースでこの Issue が修正されたら削除します。

ドキュメントのスクリーンショットは、プラグインの `docs/` を指定して `RedmineKit::Aws::ScreenshotCase` (`test/support/redmine_kit/aws/screenshot_case.rb`) で撮影します。

```ruby
require_relative '../test_helper'
require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit/aws/screenshot_case')

module RedmineKit::Aws
  module Sqs
    class ScreenshotsTest < ScreenshotCase
      self.docs = File.expand_path('../../docs', __dir__)
    end
  end
end
```

`each_language`、`shoot(name, language, selector:)`、`hide_after(selector)` があります。

<a id="redmine-kit-aws-in-the-test-image"></a>

### テスト用のイメージの Redmine Kit AWS

プラグインのテストが gem をインストールするようになるまでは、Redmine Kit AWS をチェックアウトから使います。プラグインの隣の `../redmine_kit_aws`、または `REDMINE_KIT_AWS_DIR` のディレクトリです。テストは、Redmine Kit のすべてのプラグインのテストが共有するベースイメージ (`test/Dockerfile`) で実行し、プラグインごとのイメージはありません。`bin/test_image` は、プラグインのチェックアウトと Redmine Kit AWS のチェックアウトから、git が管理する (または管理の対象になる) ファイルを、`/src/plugins` にマウントするフォルダーの `redmine_kit_aws_lambda/` と `redmine_kit_aws/` にコピーします。イメージのエントリポイントが、それを Redmine の `plugins/` にコピーします。

テストでプラグインをパスで gem として使うとき (Bundler に `boot/` を読み込ませるため) は、`bin/test_image` がプラグインのフォルダーに `PluginGemfile` を書き込みます。Redmine の Gemfile は、これをプラグインの Gemfile と一緒に読み込みます。このとき、Bundler は `redmine_kit_aws` もパスで必要とします。

```ruby
gem 'redmine_kit_aws', path: '/redmine/plugins/redmine_kit_aws', require: false
gem 'redmine_kit_aws_lambda', path: '/redmine/plugins/redmine_kit_aws_lambda'
```

CI は `redmine-kit/redmine_aws` を `redmine_kit_aws/` にチェックアウトし、`REDMINE_KIT_AWS_DIR` を設定します。[Redmine Kit AWS Lambda](https://github.com/redmine-kit/redmine_aws_lambda) がこれをすべて行っています。

プラグインの CI は、gem に関係する 2 つのジョブも実行します。`test (redmine_kit_aws release)` は、このプラグインの main に加えて、公開する gem の元である最新の `v0.*` のタグでテストを実行します。最初のリリースまでは、タグがないことを表示するだけです。`gem` は `bin/test-gem` を実行します。プラグインとこのプラグインの gem をビルドし、プラグインの導入のページのとおりに Redmine にインストールして `plugins/` にリンクし、すべてのファイルを読み込んで Redmine を起動します (`zeitwerk:check` と production 環境)。ファイルが足りない gem は、バージョンのタグで公開する前に失敗します。このプラグインの `bin/test-gem` は、導入のページのとおり (Bundler は読み込まない) と、Bundler が先に読み込む形の両方で起動します。
