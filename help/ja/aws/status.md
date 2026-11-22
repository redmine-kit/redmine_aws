# AWS の管理画面

Redmine Kit AWS は、「管理」のメニューに「AWS」を追加します。インストールした Redmine Kit AWS のプラグインごとにタブがある 1 つのページです。「AWS」で最初のタブを開きます。このページを開けるのはシステム管理者だけです。

| タブ | 追加するプラグイン |
| --- | --- |
| 「ステータス」 | Redmine Kit AWS |
| 「ジョブ」 | Redmine Kit AWS SQS |
| 「メール送信」、「メール受信」 | Redmine Kit AWS SES |
| 「S3」 | Redmine Kit AWS S3 |
| 「Cost Explorer」 | Redmine Kit AWS Cost Explorer |

プラグインの設定は、それぞれのタブにあります。「管理」›「プラグイン」で「設定」があるのは Redmine Kit AWS S3 だけで、その「S3」タブを開きます。

## ステータス

「ステータス」タブは値を表示するだけで、何も変更しません。タブを開いても AWS の API は呼びません。

- 「バージョン」: Redmine、Ruby、Rails と、インストールした Redmine Kit AWS の各プラグインのバージョンです。
- 「Parameter Store」: Redmine Kit AWS SSM があるとき、Redmine の起動時に AWS Systems Manager Parameter Store から読み込んだ環境変数の名前です。値は表示しません。
- ほかのプラグインの値: AWS Lambda では、Redmine Kit AWS Lambda が、バージョンの前に「Lambda 関数」を、あとに「読み取り専用の設定」を追加します。

## 接続テスト

「テスト」で、Redmine がデータベースと、インストールしたプラグインが使う AWS のサービスにつながるかを、リクエストの中で 1 回ずつ確認します。

- 「データベース」: 設定したデータベースに新しく接続し、データベースとそのバージョンを表示します (例: 「PostgreSQL 16.4」)。
- 「S3」、「SES」、「SQS」: それぞれ軽い呼び出しを 1 回します。Redmine Kit AWS S3 (バケットを設定しているとき)、Redmine Kit AWS SES、Redmine Kit AWS SQS が追加します。

各行には、「OK」または「失敗」、詳細、応答時間 (ミリ秒) を表示します。失敗したときは、エラーのクラス (例: `Aws::S3::Errors::Forbidden`) だけを表示し、エラーのメッセージは Redmine のログに書きます。IAM 権限、ネットワーク、Parameter Store の設定を変えたあとに実行してください。
