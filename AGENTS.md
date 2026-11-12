# AGENTS.md

Guidelines for people and coding agents working in this repository. See [README.md](README.md) for an overview and [docs/](docs/README.md) for the design.

## What this project does

Redmine AWS (`redmine_aws`) is the Redmine plugin that the Redmine AWS plugins share: the "AWS" item of the administration menu and its tabs (`RedmineAws::Admin`), the "Status" tab with the connection test, the shared settings of the AWS clients (`RedmineAws.client`) and the test support of `test/support/`. Every `redmine_aws_*` plugin requires it, without exception ([redmine_aws_lambda](https://github.com/redmine-kit/redmine_aws_lambda), [redmine_aws_s3](https://github.com/redmine-kit/redmine_aws_s3), [redmine_aws_ses](https://github.com/redmine-kit/redmine_aws_ses), [redmine_aws_sqs](https://github.com/redmine-kit/redmine_aws_sqs), [redmine_aws_ssm](https://github.com/redmine-kit/redmine_aws_ssm), [redmine_aws_costexplorer](https://github.com/redmine-kit/redmine_aws_costexplorer)). It is used by [Serverless](https://github.com/redmine-kit/serverless). It is in early development.

## Rules

- **Redmine's extension points only:** do not edit Redmine's own files. Keep Redmine's standard behaviour wherever possible.
- **Any server:** the plugin works on any server, not only on Lambda, and calls no AWS API itself. What only Lambda needs goes in redmine_aws_lambda; what one AWS service needs goes in that service's plugin.
- **One API for the other plugins:** what they use is in [docs/api.md](docs/api.md) (`RedmineAws::Admin`, `RedmineAws::AdminTab`, the `aws_admin/tabs` view, `RedmineAws.client`, `test/support/`). Keep it compatible within a minor version, and when it changes, change the plugins that use it and their required version together.
- **Tests:** the code has tests, run with Redmine's own mechanism (`bin/test` runs them in Docker; [setup.md](docs/setup.md#tests)). The test plan is in Serverless ([testing.md](https://github.com/redmine-kit/serverless/blob/main/docs/testing.md#plugin-tests)).
- **Code layout:** `lib/` and `app/` (Redmine autoloads them; `init.rb` calls `RedmineAws.setup`); `boot/redmine_aws/inflections.rb` holds the module names of the plugins' files (`ses.rb` → `RedmineAws::SES`), loaded by `init.rb`, `lib/redmine_aws.rb` and the other plugins' boot files; `test/support/` holds what the other plugins' tests load. The other plugins' code is in the same namespace ([docs/api.md](docs/api.md#namespace-and-files)).
- **No secrets in the repository.**

## Documentation

- **Two languages.** English is the source (`README.md`, `docs/`); the Japanese translation is `README.ja.md` and `docs/ja/`, with the same file names. Change both together.
- **Layout.** The READMEs stay short. The details go in `docs/`, published at https://redmine-kit.github.io/redmine_aws/ with [redmine-kit/docs-skeleton](https://github.com/redmine-kit/docs-skeleton). `docs/README.md` has the overview and the features, `docs/setup.md` the sections Requirements, Installation, Configuration, AWS resources, IAM permissions, Network, Tests and To verify, in this order (the same in every Redmine AWS plugin; IAM permissions there is one line that points to `docs/iam.md`), `docs/iam.md` the sections Permissions, Example policy, Resource-based policies and Not checked yet, `docs/api.md` the API for the other plugins. Links to the documentation of Serverless and the other plugins are absolute URLs of their documentation sites (`https://redmine-kit.github.io/<repository>/`, `.../ja/` for Japanese).
- **Anchors in Japanese.** Put `<a id="..."></a>` with the English heading's anchor before each Japanese heading.
- **Facts.** State only what has been checked, with the date and the source. Mark what has not been checked yet.
- **Japanese wording.** Follow the organization's rules (`../AGENTS.md`): plain, precise Japanese with established technical terms, half-width parentheses with a space around them, "バージョン" rather than "版", "通知" rather than "知らせ", "確認" rather than "確かめ", "インストール" rather than "入れ方".

## Commits

- English, imperative mood, 72 characters or fewer in the first line, no trailing period.
- One purpose per commit.
- Do not rewrite pushed history.
