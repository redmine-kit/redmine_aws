# IAM 権限

プラグインは自分では AWS の API を呼ばないので、プラグイン自身の権限は不要です。

<a id="permissions"></a>

## 権限

| アクション | リソース | 理由 |
| --- | --- | --- |
| なし | — | 「ステータス」のタブの S3、SES、SQS の確認は、それぞれのプラグインが追加し、それぞれの IAM 権限のページにある権限を使う ([S3](https://redmine-kit.github.io/redmine_aws_s3/ja/iam.html)、[SES](https://redmine-kit.github.io/redmine_aws_ses/ja/iam.html)、[SQS](https://redmine-kit.github.io/redmine_aws_sqs/ja/iam.html)) |

<a id="example-policy"></a>

## ポリシーの例

ありません。

<a id="resource-based-policies"></a>

## リソースベースのポリシー

ありません。

<a id="not-checked-yet"></a>

## 未確認の事項

ありません。
