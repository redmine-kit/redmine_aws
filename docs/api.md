# Plugin API

What the other Redmine Kit AWS plugins use from Redmine Kit AWS. Every Redmine Kit AWS plugin requires it, also one that uses nothing of it, in `init.rb` and in its gemspec:

```ruby
# init.rb, in Redmine::Plugin.register
requires_redmine_plugin :redmine_kit_aws, version_or_higher: '0.1.0'
```

```ruby
# <plugin>.gemspec
spec.add_dependency 'redmine_kit_aws', '~> 0.1'
```

Redmine loads plugins in alphabetical order, so `redmine_kit_aws` has run its `init.rb` before the others run theirs.

## Namespace and files

Every Redmine Kit AWS plugin puts its code under the `RedmineKitAws` namespace, which this plugin defines in `lib/redmine_kit_aws.rb`. Redmine's code loader (Zeitwerk) loads the namespace from the `lib/` of every installed plugin.

| Plugin | Module | Files |
| --- | --- | --- |
| `redmine_kit_aws_lambda` | `RedmineKitAws::Lambda` | `lib/redmine_kit_aws/lambda.rb` (the module, with `VERSION` and `setup`), `lib/redmine_kit_aws/lambda/*.rb` |
| `redmine_kit_aws_s3` | `RedmineKitAws::S3` | `lib/redmine_kit_aws/s3.rb`, `lib/redmine_kit_aws/s3/*.rb` |

The other plugins follow the same rule, with the module names of the AWS SDK for Ruby and the file names in lower case: `RedmineKitAws::SES` in `lib/redmine_kit_aws/ses.rb`, `RedmineKitAws::SQS` in `sqs.rb`, `RedmineKitAws::CostExplorer` in `costexplorer.rb`. This plugin gives Rails' code loaders these names (`boot/redmine_kit_aws/inflections.rb`); the files in a plugin's directory are named as usual (`lib/redmine_kit_aws/ses/receiver.rb` defines `RedmineKitAws::SES::Receiver`). Inside the namespace, the AWS SDK is written `::Aws::S3::Client`, so that `RedmineKitAws::S3` is never taken for `Aws::S3`. The classes in `app/` stay at the top level (`AwsS3AdminController`). The names directly in `RedmineKitAws` that this plugin defines (`VERSION`, `setup`, `client`, `Admin`, `AdminTab`, `Status`, `TestHelper`, `ScreenshotCase` and the others on this page) are not defined by other plugins.

[Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/) is the exception: it has no `lib/`, because it reads Parameter Store before Rails starts. Its `boot/redmine_kit_aws_ssm/loader.rb`, which Bundler loads, defines `RedmineKitAws::SSM` (`VERSION`, the `Loader`, and `RedmineKitAws::SSM.loaded`, the names of the variables it set), and the Status tab reads `RedmineKitAws::SSM.loaded` when the module is there (`RedmineKitAws::Status#loaded_settings`).

A `boot/` file, which Bundler loads before Rails, keeps the name of its gem (`boot/redmine_kit_aws_lambda.rb`) and defines its constants in the plugin's module (`RedmineKitAws::Lambda::Boot`). It first requires `redmine_kit_aws/inflections` (the gem of this plugin has `boot/` on the load path): with the namespace defined before Rails, the code loader names the files under `lib/redmine_kit_aws/` while it sets up, before any `init.rb` runs. It writes the modules around its constants empty (`module RedmineKitAws` and `module Lambda`) and defines nothing that this plugin defines. The code loader then skips `lib/redmine_kit_aws.rb` and the plugin's `lib/redmine_kit_aws/<plugin>.rb`, because their modules exist already; `init.rb` of each plugin loads its file:

```ruby
# init.rb of redmine_kit_aws_lambda, before Redmine::Plugin.register
require File.expand_path('lib/redmine_kit_aws/lambda', __dir__) unless defined?(RedmineKitAws::Lambda::VERSION)
```

`bin/rails zeitwerk:check` checks that every file loads. The tests of this plugin run it with a plugin whose files are named as above, also with the namespace defined before Rails; the tests of Redmine Kit AWS Lambda run it with its boot file.

## Tabs and connection checks

```ruby
RedmineKitAws::Admin.register_tab(:jobs, label: :label_aws_sqs_jobs,
                                      url: { controller: 'aws_sqs_jobs', action: 'index' }, position: 20)
RedmineKitAws::Admin.register_check(:sqs, label: :label_aws_sqs_check) { Queue.new.check }
```

| Method | Details |
| --- | --- |
| `register_tab(name, label:, url:, position:)` | A tab of the AWS page: an i18n key, a route hash and the order (Status is 10). The first tab adds the "AWS" menu item |
| `register_check(name, label:) { … }` | A connection check for the "Test" button of the Status tab. The block makes one light call and returns a short text, which the page shows. An exception shows the check as failed with the class of the error only; its message, which may name hosts, accounts or resources, goes to Redmine's log with the name of the check |
| `tabs`, `checks`, `run_checks` | The registered tabs in order, the checks, and the results of running every check |
| `routed?` | Whether the routes of `admin/aws` are drawn; the menu item is shown only then |

Call them from the plugin's setup in `init.rb`, which Redmine runs again on every code reload. The routes of a tab go under `admin/aws/`; `admin/aws` itself and `admin/aws/status` belong to this plugin.

## Tab controllers and views

```ruby
class AwsSqsJobsController < ApplicationController
  include RedmineKitAws::AdminTab
end
```

`RedmineKitAws::AdminTab` sets Redmine's administration layout, selects the "AWS" menu item and allows administrators only (`require_admin`). The view starts with the tabs, `selected` being the name given to `register_tab`:

```erb
<%= render partial: 'aws_admin/tabs', locals: { selected: 'jobs' } %>
```

## The Status tab

```ruby
RedmineKitAws::Admin.register_status_section(:lambda_function, partial: 'aws_lambda/function', position: 10)
```

`register_status_section(name, partial:, position:)` adds a section to the Status tab: a view partial, rendered with the local `status` (a `RedmineKitAws::Status`), at a position among the tab's own sections (Versions 20, Parameter Store 30). The connection test comes last. `status_sections` returns the sections in order. The tab lists the versions of the family's plugins: `redmine_kit_aws` and the plugins whose ids start with `redmine_kit_aws_` (`RedmineKitAws::Status.family?`).

## Values

```erb
<h3><%= l(:label_aws_lambda_function) %></h3>
<%= render partial: 'aws_admin/values', locals: { rows: [
      { name: l(:field_aws_lambda_function_name), value: name || '-' },
      { name: l(:field_aws_lambda_function_role), value: role || '-', note: 'REDMINE_ROLE' }
    ] } %>
```

`aws_admin/values` shows values that are not edited (versions, states, what a check found) the way Administration › Information does ([Redmine Design Guide: Information](https://redmine-kit.github.io/design-guide/information.html)): a `table.list.values` without a header row, followed by a `<br />`. Each row is a hash: `name` (the `td.name`), and optionally `value` (a `td.value`), `note` (an `em.info` under the value, such as the environment variable or the setting the value comes from) and `ok` (`true` or `false`: a `td.tick` with Redmine's icon, and the row's class `ok` or `failed`). `css` adds classes to the table (the connection test uses `checks`). The partial adds its stylesheet (`assets/stylesheets/aws_values.css`) to the page's `header_tags` once, however many tables the page has: the names stay on one line, and a long value (such as an image URI with its digest) wraps anywhere instead of squeezing them. Every Redmine Kit AWS plugin shows read-only values with it, on the Status tab and on its own tabs.

## AWS clients

```ruby
RedmineKitAws.client(::Aws::S3::Client)
RedmineKitAws.client(::Aws::CostExplorer::Client, region: 'us-east-1', http_open_timeout: 5, retry_limit: 2)
```

| Method | Details |
| --- | --- |
| `client(klass, **options)` | A client of the SDK class. Its options are, from weakest to strongest: the region of `region`, the options given here, `client_options` |
| `region` | `AWS_REGION`, then `AWS_DEFAULT_REGION`; nil when neither is set |
| `client_options`, `client_options=` | Options for every client built with `client`. Empty unless set: the SDK then reads the credentials, the region and the endpoints as usual (`AWS_ENDPOINT_URL`, `AWS_ENDPOINT_URL_<SERVICE>`). Tests set them to send requests to AWS Emulator (LocalStack or moto only where a plugin's testing docs say so), or to SDK stubs for errors and account states that can't be set up otherwise |
| `env_true?(name)` | Whether an environment variable is `true`, in any case, spaces ignored |

This plugin has no AWS SDK gem; each plugin depends on the SDK gems of the services it calls.

## Compatibility

The plugins depend on `redmine_kit_aws ~> 0.1` (0.1 or later, below 1.0). While this plugin is at 0.x, a new minor or patch version keeps what this page describes working for them: it may add to it, but does not change or remove what they use. A change that breaks them comes only with 1.0, and the plugins then depend on the new major version. Each plugin's CI also tests with the newest released 0.x version (`test (redmine_kit_aws release)`, [below](#redmine-kit-aws-in-the-test-image)).

## Tests of the plugins

### Test helpers

`test/support/redmine_kit_aws/` is in the repository and in the gem. A plugin's `test/test_helper.rb` loads it after Redmine's test helper, from wherever `redmine_kit_aws` is installed:

```ruby
require File.expand_path('../../../test/test_helper', __dir__)
require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit_aws/test_helper')
```

| `RedmineKitAws::TestHelper` | Details |
| --- | --- |
| `with_env(values) { … }` | Sets environment variables for the block (`nil` unsets one) and restores them |
| `with_aws_client_options(**options) { … }` | Merges options into `RedmineKitAws.client_options` for the block, for example the `endpoint:` of AWS Emulator |
| `stub_aws_client(klass, **stubs)` | A client with SDK response stubs (`stub_responses`), in `us-east-1` with test credentials; without stubs, every call returns empty data |
| `TEST_REGION`, `TestHelper.credentials` | The region (`us-east-1`) and the credentials (`test`/`test`) of clients in tests, which AWS Emulator (with its authentication off), LocalStack and moto accept |

The screenshots of the docs use `RedmineKitAws::ScreenshotCase` (`test/support/redmine_kit_aws/screenshot_case.rb`), with the plugin's `docs/`:

```ruby
require_relative '../test_helper'
require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit_aws/screenshot_case')

module RedmineKitAws
  module SQS
    class ScreenshotsTest < ScreenshotCase
      self.docs = File.expand_path('../../docs', __dir__)
    end
  end
end
```

It has `each_language`, `shoot(name, language, selector:)` and `hide_after(selector)`.

### Redmine Kit AWS in the test image

Until the plugins' tests install the gem, they take Redmine Kit AWS from a checkout: `../redmine_kit_aws` next to the plugin, or the directory in `REDMINE_KIT_AWS_DIR`, given to Docker as a build context of its own:

```sh
docker buildx build --build-context redmine_kit_aws="${REDMINE_KIT_AWS_DIR:-../redmine_kit_aws}" -f test/Dockerfile .
```

```dockerfile
COPY --from=redmine_kit_aws . plugins/redmine_kit_aws/
```

When the test image adds the plugin to `Gemfile.local` as a gem by path, Bundler needs `redmine_kit_aws` by path too (`gem 'redmine_kit_aws', path: 'plugins/redmine_kit_aws', require: false`). CI checks out `redmine-kit/redmine_aws` into `redmine_kit_aws/` and sets `REDMINE_KIT_AWS_DIR`. [Redmine Kit AWS Lambda](https://github.com/redmine-kit/redmine_aws_lambda) does all of this.

The plugins' CI also runs two jobs around the gem. `test (redmine_kit_aws release)` runs the tests with the newest `v0.*` tag of this plugin, the source of the published gem, as well as with its main; until the first release it only notes that there is none. `gem` runs `bin/test-gem`, which builds the plugin's gem and this plugin's, installs them into Redmine as the plugin's setup page says, links them into `plugins/` and boots Redmine with every file loaded (`zeitwerk:check`, and the production environment), so that a gem that misses a file fails before a version tag publishes it. This plugin's own `bin/test-gem` boots it both as the setup page installs it (not required by Bundler) and required early by Bundler.
