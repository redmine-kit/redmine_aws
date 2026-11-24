# 導入

Redmine Kit AWS を使う Redmine に必要なもの (インストール、設定、AWS リソース、IAM 権限、ネットワーク) です。Redmine Kit AWS のプラグインはどれもこのプラグインを必要とするので、それらといっしょにインストールします。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて用意します。このページは、手作業で用意するときや、Serverless が作成するものを確認するときのためのものです。

<a id="requirements"></a>

## 動作環境

- Redmine 7.0 以降。プラグインはデータベースに依存しません。テストは PostgreSQL 16 で実行します。
- どのサーバーでも動きます。AWS Lambda、EC2、ECS、それ以外の環境。

<a id="required-plugins"></a>

### 必須プラグイン

ありません。

<a id="optional-plugins"></a>

### オプションのプラグイン

| プラグイン | 使える機能 |
| --- | --- |
| [Redmine Kit AWS SSM](https://github.com/redmine-kit/redmine_aws_ssm) | 「ステータス」タブの Parameter Store の状態 |
| [Redmine Kit UI](https://github.com/redmine-kit/redmine_kit_ui) | 新しい UI の「ステータス」タブの画面 ([admin.md](admin.md#in-the-new-ui)) |
| [Redmine Kit Help](https://github.com/redmine-kit/redmine_help) | ヘルプのパネルに表示するこのプラグインのヘルプ |

<a id="installation"></a>

## インストール

1. プラグインを gem としてインストールするか ([gem](#gem))、Redmine の `plugins/` にチェックアウトを置きます ([gem を使わないとき](#without-the-gem))。ほかの Redmine Kit AWS のプラグインの gem はこの gem に依存するので、どれかをインストールすると、このプラグインもインストールされます。チェックアウトでは、それらと同じ `plugins/` に置きます。順序は問いません。`redmine_kit_aws` がないときは、Redmine が起動時に停止し、その名前を示します ([必須プラグイン](#required-plugins))。
2. Redmine のフォルダーで `bundle install` を実行します。
3. マイグレーションは不要です。
4. Redmine を再起動します。

<a id="gem"></a>

### gem

**gem として** (推奨): Redmine の `Gemfile.local` に、GitHub Packages にある Redmine Kit のレジストリ (`https://rubygems.pkg.github.com/redmine-kit`。`bin/release` が公開します: [リリース](#releasing)) のブロックで追加します。このプラグインが必要とするプラグイン ([必須プラグイン](#required-plugins)) も Bundler がそこから取得し、これらの gem を rubygems.org から取得することはありません。レジストリには、公開のパッケージでも `read:packages` を持つ GitHub のトークンが必要です。Bundler には環境変数 `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` (`<user>:<token>`) で渡し、リポジトリのファイルには書きません。

```ruby
# Redmine の Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_kit_aws'
end
```

**リポジトリから** (開発用): Bundler は gem を git から取得します。Bundler は gem が必要とするプラグインを git からは取得しないので、その行も追加します。

```ruby
# Redmine の Gemfile.local
gem 'redmine_kit_aws', git: 'https://github.com/redmine-kit/redmine_aws.git', branch: 'main'
```

Bundler が `boot/redmine_kit_aws.rb` を読み込み、gem のフォルダーを Redmine のプラグインローダーに渡します。Redmine は `plugins/` のプラグインと同じく、gem の `init.rb` を実行し、アセット、文字列、ビュー、マイグレーションを使い、`lib/` と `app/` を Rails のコードローダーに追加し、ルートを追加するので、`plugins/` へのリンクは不要です。`plugins/` に同じ id のフォルダーがあれば、そちらが優先されます。 gem には実行に必要なファイルが入り、プラグインの `Gemfile` は入りません。

<a id="without-the-gem"></a>

### gem を使わないとき

リポジトリを Redmine の `plugins/` にクローンします。フォルダー名は、リポジトリ名ではなく、プラグインの ID にします。

```sh
git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_kit_aws
```

Rails の起動前に読み込むものがないので、`Gemfile.local` に行を追加する必要はありません。Redmine の `Gemfile` がプラグインの `Gemfile` を読み込み、使う gem を追加します。

<a id="configuration"></a>

## 設定

プラグイン自身の設定はありません。各プラグインの AWS クライアントは、AWS SDK と同じように、認証情報、リージョン、エンドポイントを読み込みます。

| キー | 説明 | パラメーター |
| --- | --- | --- |
| `AWS_REGION` | AWS クライアントのリージョン。プラグインが自分のリージョンを指定する場合を除く | Lambda が設定する。それ以外では `AWS_REGION` か `AWS_DEFAULT_REGION` |

起動時に SSM Parameter Store から設定とシークレットを読み込むには、[Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/ja/) を使います。これをインストールすると、「ステータス」のタブに、読み込んだパラメーターの名前が表示されます。

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

テストは `test/` にあり、Redmine の標準の仕組みで、Redmine 7.0.3 と PostgreSQL 16 で実行します。Apple container がインストールされて動いていれば Apple container で、そうでなければ Docker で実行します (`CONTAINER_CLI=container` または `docker` で選べます)。1 台のマシンで同時に実行する redmine-kit のリポジトリのテストは 2 つまでで (`TEST_SLOTS`)、空きを待ってから始まります。`bin/test` は、プラグインのテストを [Redmine Kit UI](https://github.com/redmine-kit/redmine_kit_ui) をインストールした状態 (隣のチェックアウト `../redmine_kit_ui` の `HEAD`。`REDMINE_KIT_UI` と `REDMINE_KIT_UI_REF` で別のものを選べます) と、インストールしない状態で実行し、そのあと、管理メニューとプラグインに関係する Redmine 本体のテストを Redmine Kit UI なしで実行します。CI は、トークン `REDMINE_KIT_UI_TOKEN` で redmine_kit_ui をプラグインの隣にチェックアウトします。`bin/test --redmine` は、プラグインをインストールした状態で Redmine 本体のすべてのテストを実行します。CI はこちらを使い、静的チェックとテストを Ruby 3.2 と 4.0 で実行します。ローカルでは、`TEST_RUBY=3.2 bin/test` (または `bin/lint`) で Ruby 3.2 で実行します。

実行は、終わったときに (テストの成功、失敗、中断のいずれでも)、自分が起動したサービスのコンテナを停止します (削除はしません)。実行の前から動いていたコンテナと、このリポジトリの別の実行がまだ使っているコンテナは、そのまま動かしておきます。`KEEP_SERVICES=1` を指定すると、実行の後も動かしたままにします。

`COVERAGE=1` を付けると、プラグインのテストは、プラグイン自身のファイルのカバレッジ (SimpleCov。Cobertura の XML の `coverage/coverage.xml`) も出力し、1 プロセスで実行します。CI は Ruby 4.0 でこれを有効にし、レポートを `plugin` フラグで [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws) に送信します。送信の認証は OIDC (`id-token: write`) なので、トークンをシークレットに保存しません。Codecov のステータスは参考情報で、コミットや Pull Request を失敗にしません (`codecov.yml`)。

`bin/test-gem` は、組織のプラグインのテンプレートと同じく gem を確認します。チェックアウトからプラグインと Redmine Kit AWS の gem をビルドし、チェックアウトを `plugins/` から外して [gem](#gem) のとおりにインストールし、すべてのファイルを読み込んで Redmine を起動します (`zeitwerk:check` と、起動時にすべてを読み込む production 環境)。各プラグインが gem のフォルダーから、boot のファイル、コード、ルート、マイグレーション、アセットとともに読み込まれることを確認し、チェックアウトを `plugins/` に戻して、チェックアウトが優先されることも確認します。CI と `bin/release` もこれを実行するので、gem にないファイルがあれば、ほかのプラグインや Serverless がインストールする前に失敗します。

`bin/test-family` は、Redmine Kit AWS のプラグインをまとめてチェックアウトとして `plugins/` に置き (このプラグインと、隣にあるほかのプラグイン。Gemfile.local の行が必須の DSQL と SSM を除く)、[gem を使わないとき](#without-the-gem) のとおり Gemfile.local に行を書かずに Redmine を起動します。マイグレーションし、`zeitwerk:check` と production 環境で起動して、すべてのプラグインが `plugins/` から登録されること、Rails より前に実行する必要がある boot のファイルが実行されたことを確認します。2 つのプラグインが同じ gem を交わらない範囲で指定していると失敗します。

```sh
bin/test            # redmine_kit_ui あり・なしのプラグインのテストと、関係する Redmine のテスト
bin/test --redmine  # Redmine のすべてのテストも実行する
COVERAGE=1 bin/test # カバレッジを coverage/coverage.xml に出力する
bin/test-gem        # gem をビルド・インストールし、gem から、次に plugins/ から起動する
bin/test-family     # Redmine Kit AWS のプラグインを gem なしでまとめて plugins/ に置いて起動する
bin/lint            # RuboCop
bin/screenshots     # admin.md のスクリーンショット
bin/services --down # PostgreSQL (と Chromium) を停止する
```

新しい UI のモジュールは、`frontend/` で Node.js (バージョンは `frontend/.nvmrc`) を使って確認します。`.npmrc` には `ignore-scripts=true` があり、`@redmine-kit/ui` と `@redmine-kit/plugin` は、隣にある ui リポジトリのチェックアウト (`../../ui/packages/…`) から取得します。

```sh
cd frontend
npm install
npm run check       # 型チェック、コンポーネントのテスト (vitest)、ビルド、kit-check-ui、Storybook のビルド
npm run storybook   # タブの状態の Storybook (ポート 6008)
```

ほかのプラグインのテストは、このプラグインを隣のチェックアウト (`../redmine_kit_aws`、または `REDMINE_KIT_AWS_DIR` のディレクトリ) から読み込みます ([api.md](api.md#tests-of-the-plugins))。

<a id="releasing"></a>
## リリース

`bin/release` は、gemspec のバージョンの gem を GitHub Packages の Redmine Kit のレジストリに公開します。実行できるのは変更のない `main` からだけで、バージョンが最後のタグ `v<version>` より新しいこと、必須プラグインがレジストリから範囲どおりに解決できること (`config/dependencies.yml`)、`bin/lint`、`bin/test`、`bin/test-gem` が成功することが条件です。公開には `~/.gem/credentials` のキー `github` (`:github: Bearer <token>`。`write:packages` を持つトークン) を使い、レジストリの読み取りには `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` を使います。トークンはリポジトリにも出力にも含めません。署名付きのタグ `v<version>` を作り、それをプッシュするコマンドを表示します。バージョンはセマンティックバージョニングに従います。このプラグインを使うプラグインが動かなくなる変更ではメジャーバージョン (1.0 より前はマイナーバージョン) を上げ、それを必要とするプラグインの範囲も変えます。

<a id="to-verify"></a>

## 未確認の事項

ありません。
