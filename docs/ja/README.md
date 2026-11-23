# Redmine Kit AWS

Redmine Kit AWS (`redmine_kit_aws`) は、Redmine Kit AWS のプラグインが共通で使う Redmine のプラグインです。各プラグインの管理画面を Redmine の管理メニューの 1 つの項目「AWS」の下にまとめ、接続テストのある「ステータス」のタブを表示し、AWS クライアントの共通設定を持ちます。AWS Lambda でもそれ以外でも、どのサーバーでも動きます。Redmine 本体のファイルは書き換えず、Redmine の標準の拡張機能だけを使います。今は開発の初期です。

- [導入](setup.md): 動作環境、インストール、設定、AWS リソース、ネットワーク、テスト
- [IAM 権限](iam.md): 権限、ポリシーの例、リソースベースのポリシー
- [管理画面](admin.md): AWS メニュー、ステータスのタブ
- [プラグインの API](api.md): ほかのプラグインが使うもの。タブ、接続テスト、ステータスのタブ、AWS クライアント、テストの支援

<a id="features"></a>

## 機能

| 機能 | 内容 | 有効にする条件 | 資料 |
| --- | --- | --- | --- |
| AWS メニュー | Redmine の管理メニューの 1 つの項目「AWS」。そのページに、インストールした Redmine Kit AWS のプラグインごとのタブがある | システム管理者 | [admin.md](admin.md#the-aws-menu) |
| ステータス | Redmine と Redmine Kit AWS のプラグインのバージョン、SSM Parameter Store から読み込んだ設定、ほかのプラグインが追加する値、データベースと AWS のサービスへの接続テスト | システム管理者 | [admin.md](admin.md#status) |
| AWS クライアント | どのプラグインの AWS クライアントにも渡すリージョンとオプション。テストでは、これですべてのリクエストを AWS Emulator に送る (LocalStack と moto は、プラグインのテストの資料が示すところだけ)。エラーとアカウントの状態は SDK のスタブに送る | 常に (設定しなければ空) | [api.md](api.md#aws-clients) |

Redmine Kit AWS のプラグイン (`redmine_kit_aws_*`) は、例外なく、どれも Redmine Kit AWS を必要とします。各プラグインは `config/dependencies.yml` (`requires`) にこれを書くので、Redmine Kit AWS がなければ Redmine は起動時に停止し、その名前を示します。また、各プラグインの gem は `redmine_kit_aws` の gem に依存するので、プラグインの gem をインストールすると Redmine Kit AWS もインストールされます ([setup.md](setup.md#installation))。プラグインは次のとおりです。

| プラグイン | 内容 |
| --- | --- |
| [Redmine Kit AWS Lambda](https://redmine-kit.github.io/redmine_aws_lambda/ja/) | Redmine を AWS Lambda で動かす。Lambda Web Adapter の `/events`、転送されたホスト、Lambda で使えない Redmine の設定 |
| [Redmine Kit AWS S3](https://redmine-kit.github.io/redmine_aws_s3/ja/) | S3 の添付ファイル。署名付き URL で CloudFront を通すアップロードとダウンロード、`/tmp` のキャッシュ |
| [Redmine Kit AWS SES](https://redmine-kit.github.io/redmine_aws_ses/ja/) | SES でのメール。エラーの種類別の再送信、受信と取り込み、プロジェクト別のアドレス |
| [Redmine Kit AWS SQS](https://redmine-kit.github.io/redmine_aws_sqs/ja/) | SQS でのジョブ。`aws-activejob-sqs` の設定、ジョブの失敗の記録、再送信 |
| [Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/ja/) | SSM Parameter Store の設定とシークレット。Rails が起動する前に読み込む。「ステータス」のタブに、設定した変数の名前が表示される |
| [Redmine Kit AWS Cost Explorer](https://redmine-kit.github.io/redmine_aws_costexplorer/ja/) | Cost Explorer から取得する AWS アカウントのコスト |

<a id="code-layout"></a>

## コード構成

タブと接続テストの登録先は `RedmineKit::Aws::Admin` (`lib/redmine_kit/aws/admin.rb`)、メニューの項目のページは `AwsAdminController`、ステータスのタブは `AwsStatusController` と `RedmineKit::Aws::Status`、AWS クライアントの設定は `RedmineKit::Aws` (`lib/redmine_kit/aws.rb`) です。Redmine が `lib/` と `app/` を読み込み、`init.rb` がステータスのタブとデータベースの確認を登録します。新しい UI のタブは、`config/kit_ui.yml` と、`frontend/` からビルドするモジュールです (`npm run build` が `assets/javascripts/kit/aws.js` と `assets/stylesheets/kit/aws.css` を出力し、これをコミットします。`npm run check` は、型チェック、テスト、ビルド、Storybook のビルドを実行します)。`test/support/redmine_kit/aws/` には、ほかのプラグインのテストが読み込むテストヘルパーがあります。ほかの Redmine Kit AWS のプラグインも、コードを同じ名前空間に置きます (`RedmineKit::Aws::Lambda`、`RedmineKit::Aws::S3` など。[api.md](api.md#namespace-and-files))。

プラグインは自分では AWS の API を呼ばないので、AWS SDK の gem は不要です。AWS を呼ぶプラグインが、それぞれの gem を持ちます。データベースのテーブルを追加しないので、実行する migration はありません。コードには、Redmine の標準の仕組みでテストを書いています ([setup.md](setup.md#tests))。

<a id="tests"></a>

### テスト

| 対象 | 確認すること |
| --- | --- |
| AWS メニュー | タブを追加で登録しても、メニューの項目は 1 つ。最初のタブを開く。システム管理者だけ |
| ステータス | バージョン。Redmine Kit AWS SSM が設定した変数の名前。プラグインが追加する項目とその順序 (値、パーシャル、行なし、非表示)。シークレットを画面に出さない。データベースの確認と、失敗する確認。システム管理者だけ |
| 新しい UI のステータス | Redmine Kit UI がある状態で、マニフェストが使われ、画面がシステム管理者だけに表示される。CSRF トークン付きの kit リクエストへのタブの JSON (項目、名前だけ、接続テスト、失敗した確認の例外のクラス)。トークンがない場合、ほかのユーザー、kit のヘッダーがない場合は拒否する。モジュールのコンポーネント (`frontend/`、`npm test`)。項目の順序、「表示するデータがありません」、「テスト」とその結果、エラーの表示、スケルトン |
| AWS クライアント | `AWS_REGION` と `AWS_DEFAULT_REGION` から決まるリージョン。オプションの優先順位。テストヘルパーがオプションと環境変数を設定して元に戻す |
| コードの読み込み | 新しいプロセスで、各プラグインと同じ名前のファイル (`RedmineKit::Aws::Ses` の `ses.rb` など) を持つプラグインを使って確認する。`zeitwerk:check` が通り、モジュールを読み込める。ほかのプラグインの boot のファイルのように Rails より前に名前空間 `RedmineKit::Aws` を定義しても同じ |

<a id="sponsors"></a>

## スポンサー

<Sponsors ids="keyselect"><a href="https://www.keyselect.co.jp/">KEY SELECT</a></Sponsors>

<a id="license"></a>

## ライセンス

Redmine Kit AWS は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](../../LICENSE) を参照してください。Redmine の非公式のプラグインです。
