# Plugin API

What the other Redmine Kit AWS plugins use from Redmine Kit AWS. Every Redmine Kit AWS plugin requires it, also one that uses nothing of it, in its `config/dependencies.yml`, as every plugin of Redmine Kit lists the plugins it requires:

```yaml
# config/dependencies.yml
requires:
  redmine_kit_aws: "~> 0.1"
```

```ruby
# init.rb, first: stops Redmine at boot and names a required plugin that is missing
load File.expand_path('config/dependencies.rb', __dir__)
```

The gemspec depends on the gems of `requires` at their ranges. The check doesn't depend on the order in which Redmine runs the plugins' `init.rb`; code that runs in `init.rb` uses `RedmineKit::Aws` through Rails' code loader, which has every plugin's `lib/` by then.

## Namespace and files

Every Redmine Kit AWS plugin puts its code under the `RedmineKit::Aws` namespace, which this plugin defines in `lib/redmine_kit/aws.rb`. `RedmineKit` above it is the namespace of every Redmine Kit plugin and belongs to none: no plugin has `lib/redmine_kit.rb`, and Redmine's code loader (Zeitwerk) makes the module from the plugins' `lib/redmine_kit/` directories, since Redmine makes each plugin's `lib/` a root directory of the loader. A test of each plugin fails if it has `lib/redmine_kit.rb`.

| Plugin | Module | Files |
| --- | --- | --- |
| `redmine_kit_aws_lambda` | `RedmineKit::Aws::Lambda` | `lib/redmine_kit/aws/lambda.rb` (the module, with `VERSION` and `setup`), `lib/redmine_kit/aws/lambda/*.rb` |
| `redmine_kit_aws_s3` | `RedmineKit::Aws::S3` | `lib/redmine_kit/aws/s3.rb`, `lib/redmine_kit/aws/s3/*.rb` |

The other plugins follow the same rule, with the names the code loader gives the files by default: `RedmineKit::Aws::Ses` in `lib/redmine_kit/aws/ses.rb`, `RedmineKit::Aws::Sqs` in `sqs.rb`, `RedmineKit::Aws::Ssm`, `RedmineKit::Aws::Costexplorer` in `costexplorer.rb`, `RedmineKit::Aws::Dsql`, and `lib/redmine_kit/aws/ses/receiver.rb` defines `RedmineKit::Aws::Ses::Receiver`. Inside `RedmineKit`, `Aws` is `RedmineKit::Aws`, so the AWS SDK is always written `::Aws::S3::Client`. The classes in `app/` stay at the top level (`AwsS3AdminController`). The names directly in `RedmineKit::Aws` that this plugin defines (`VERSION`, `setup`, `client`, `Admin`, `AdminTab`, `Status`, `TestHelper`, `ScreenshotCase` and the others on this page) are not defined by other plugins.

[Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/) is the exception: it has no `lib/`, because it reads Parameter Store before Rails starts. Its `boot/redmine_kit_aws_ssm/loader.rb`, which Bundler loads, defines `RedmineKit::Aws::Ssm` (`VERSION`, the `Loader`, and `RedmineKit::Aws::Ssm.loaded`, the names of the variables it set), and the Status tab reads `RedmineKit::Aws::Ssm.loaded` when the module is there (`RedmineKit::Aws::Status#loaded_settings`).

A `boot/` file, which Bundler loads before Rails, keeps the name of its gem (`boot/redmine_kit_aws_lambda.rb`) and defines its constants in the plugin's module (`RedmineKit::Aws::Lambda::Boot`). It writes the modules around its constants empty and nested (`module RedmineKit`, `module Aws` and `module Lambda`; not `module RedmineKit::Aws`, which needs `RedmineKit` defined) and defines nothing that this plugin defines. The code loader then skips `lib/redmine_kit/aws.rb` and the plugin's `lib/redmine_kit/aws/<plugin>.rb`, because their modules exist already; `init.rb` of each plugin loads its file:

```ruby
# init.rb of redmine_kit_aws_lambda, before Redmine::Plugin.register
require File.expand_path('lib/redmine_kit/aws/lambda', __dir__) unless defined?(RedmineKit::Aws::Lambda::VERSION)
```

`bin/rails zeitwerk:check` checks that every file loads. The tests of this plugin run it with a plugin whose files are named as above, also with the namespace defined before Rails; the tests of Redmine Kit AWS Lambda run it with its boot file.

## Tabs and connection checks

```ruby
RedmineKit::Aws::Admin.register_tab(:jobs, label: :label_aws_sqs_jobs,
                                      url: { controller: 'aws_sqs_jobs', action: 'index' }, position: 20)
RedmineKit::Aws::Admin.register_check(:sqs, label: :label_aws_sqs_check) { Queue.new.check }
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
  include RedmineKit::Aws::AdminTab
end
```

`RedmineKit::Aws::AdminTab` sets Redmine's administration layout, selects the "AWS" menu item and allows administrators only (`require_admin`). The view starts with the tabs, `selected` being the name given to `register_tab`:

```erb
<%= render partial: 'aws_admin/tabs', locals: { selected: 'jobs' } %>
```

## The Status tab

```ruby
RedmineKit::Aws::Admin.register_status_section(:lambda_function, label: :label_aws_lambda_function,
                                                                 position: 10) do |view, _status|
  [{ name: view.l(:field_aws_lambda_function_role), value: role || '-', note: 'REDMINE_ROLE' }]
end
```

`register_status_section(name, label:, position:) { |view, status| … }` adds a section of values to the Status tab, at a position among the tab's own sections (Versions 20, Parameter Store 30). The connection test comes last. `label` is the i18n key of its heading. The block gets the view (Redmine's helpers: `l`, `format_object`, `number_with_delimiter`) and the status (a `RedmineKit::Aws::Status`), and returns the rows: hashes with `name`, and optionally `value` and `note`, as [Values](#values) takes them, and `code: true` for a name that is code (a parameter's name). It returns `[]` for "No data to display", or `nil` to leave the section out. Both UIs draw such a section from the same rows: Redmine's page with `aws_admin/values`, the new UI from the tab's JSON ([The new UI](#the-new-ui)). `RedmineKit::Aws::Status#sections(view)` gives the sections in order, with their rows.

`register_status_section(name, partial:, position:)` adds a view partial instead, rendered with the local `status`. Only Redmine's page draws it; the new UI leaves it out. A section takes either a label and a block or a partial (`ArgumentError` otherwise). `status_sections` returns the sections in order. The tab lists the versions of the family's plugins: `redmine_kit_aws` and the plugins whose ids start with `redmine_kit_aws_` (`RedmineKit::Aws::Status.family?`).

## Values

```erb
<h3><%= l(:label_aws_lambda_function) %></h3>
<%= render partial: 'aws_admin/values', locals: { rows: [
      { name: l(:field_aws_lambda_function_name), value: name || '-' },
      { name: l(:field_aws_lambda_function_role), value: role || '-', note: 'REDMINE_ROLE' }
    ] } %>
```

`aws_admin/values` shows values that are not edited (versions, states, what a check found) the way Administration › Information does ([Redmine Design Guide: Information](https://redmine-kit.github.io/design-guide/information.html)): a `table.list.values` without a header row, followed by a `<br />`. Each row is a hash: `name` (the `td.name`), and optionally `value` (a `td.value`), `note` (an `em.info` under the value, such as the environment variable or the setting the value comes from) and `ok` (`true` or `false`: a `td.tick` with Redmine's icon, and the row's class `ok` or `failed`). `css` adds classes to the table (the connection test uses `checks`). The partial adds its stylesheet (`assets/stylesheets/aws_values.css`) to the page's `header_tags` once, however many tables the page has: the names stay on one line, and a long value (such as an image URI with its digest) wraps anywhere instead of squeezing them. Every Redmine Kit AWS plugin shows read-only values with it, on the Status tab and on its own tabs.

## The new UI

With [Redmine Kit UI](https://github.com/redmine-kit/redmine_kit_ui) installed, the AWS page is drawn by the new UI ([admin.md](admin.md#in-the-new-ui)), as an Administration page of several plugins (redmine_kit_ui's [Kit-aware plugins](https://github.com/redmine-kit/redmine_kit_ui/blob/main/docs/plugins-kit.md#an-administration-page-of-several-plugins)). This plugin's manifest (`config/kit_ui.yml`) gives the admin menu's item `aws` its icon and declares the Status tab:

```yaml
menus:
  admin_menu:
    aws: { icon: server }
screens:
  - { path: /admin/aws/status, component: AwsStatus, layout: admin, menu_item: aws, title: label_aws, tab: label_aws_status, position: 10 }
```

- **A tab** of another plugin is a screen of that plugin's own manifest, at its tab's route under `admin/aws/`, with `layout: admin`, `menu_item: aws`, `title: label_aws`, its tab's label as `tab` and the position of its `register_tab` as `position`. The new UI draws the page's card, the header "AWS" and one strip of the tabs of every plugin; the plugin's component draws the tab's content, from the JSON of the tab's controller (the same actions as Redmine's page, behind `require_admin`).
- **A section of the Status tab** is a section of values (`register_status_section` with a label and a block): the tab's JSON gives its rows, and `AwsStatus` draws them. A plugin needs no code of the new UI for it.
- **The tab's JSON**, for the browser's session (kit requests): `GET /admin/aws/status.json` gives `{ sections: [{ name, label, rows }] }`, the sections of values only; `POST /admin/aws/status/check.json` runs the checks and gives `{ results: [{ name, ok, value, note }] }` (the check's name, whether it passed, what it returned or the class of its error, the time it took as "12 ms"). Both are behind `require_admin`.

## AWS clients

```ruby
RedmineKit::Aws.client(::Aws::S3::Client)
RedmineKit::Aws.client(::Aws::CostExplorer::Client, region: 'us-east-1', http_open_timeout: 5, retry_limit: 2)
```

| Method | Details |
| --- | --- |
| `client(klass, **options)` | A client of the SDK class. Its options are, from weakest to strongest: the region of `region`, the options given here, `client_options`. An option given here as nil is left out, so that the SDK's own chain decides it (the SDK takes an explicit `credentials: nil` or `region: nil` as given and then can't sign) |
| `region` | `AWS_REGION`, then `AWS_DEFAULT_REGION`; nil when neither is set |
| `client_options`, `client_options=` | Options for every client built with `client`. Empty unless set: the SDK then reads the credentials, the region and the endpoints as usual (`AWS_ENDPOINT_URL`, `AWS_ENDPOINT_URL_<SERVICE>`). Tests set them to send requests to AWS Emulator (LocalStack or moto only where a plugin's testing docs say so), or to SDK stubs for errors and account states that can't be set up otherwise |
| `env_true?(name)` | Whether an environment variable is `true`, in any case, spaces ignored |

This plugin has no AWS SDK gem; each plugin depends on the SDK gems of the services it calls.

## Compatibility

The plugins depend on `redmine_kit_aws ~> 0.1` (0.1 or later, below 1.0). While this plugin is at 0.x, a new minor or patch version keeps what this page describes working for them: it may add to it, but does not change or remove what they use. A change that breaks them comes only with 1.0, and the plugins then depend on the new major version. Each plugin's CI also tests with the newest released 0.x version (`test (redmine_kit_aws release)`, [below](#redmine-kit-aws-in-the-test-image)).

## Tests of the plugins

### Test helpers

`test/support/redmine_kit/aws/` is in the repository and in the gem. A plugin's `test/test_helper.rb` loads it after Redmine's test helper, from wherever `redmine_kit_aws` is installed:

```ruby
require File.expand_path('../../../test/test_helper', __dir__)
require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit/aws/test_helper')
```

| `RedmineKit::Aws::TestHelper` | Details |
| --- | --- |
| `with_env(values) { … }` | Sets environment variables for the block (`nil` unsets one) and restores them |
| `with_aws_client_options(**options) { … }` | Merges options into `RedmineKit::Aws.client_options` for the block, for example the `endpoint:` of AWS Emulator |
| `stub_aws_client(klass, **stubs)` | A client with SDK response stubs (`stub_responses`), in `us-east-1` with test credentials; without stubs, every call returns the SDK's stub data (placeholder values of the response's shape) |
| `TEST_REGION`, `TestHelper.credentials` | The region (`us-east-1`) and the credentials (`test`/`test`) of clients in tests, which AWS Emulator (with its authentication off), LocalStack and moto accept |

It also makes SDK clients with response stubs work under Mocha, which Redmine's test helper loads (`RedmineKit::Aws::SdkConfigStubs`). Since aws-sdk-core 3.270.0, Mocha's `Object#stubs` hides the client's `stubs` option, and a client built with stubs, or a call on it, raises `ArgumentError` ([aws/aws-sdk-ruby#3501](https://github.com/aws/aws-sdk-ruby/issues/3501), open on 2026-11-19). It goes when an SDK release fixes that issue.

The screenshots of the docs use `RedmineKit::Aws::ScreenshotCase` (`test/support/redmine_kit/aws/screenshot_case.rb`), with the plugin's `docs/`:

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

It has `each_language`, `shoot(name, language, selector:)` and `hide_after(selector)`.

### Redmine Kit AWS in the test image

Until the plugins' tests install the gem, they take Redmine Kit AWS from a checkout: `../redmine_kit_aws` next to the plugin, or the directory in `REDMINE_KIT_AWS_DIR`. The tests run in the base image that every Redmine Kit plugin's tests share (`test/Dockerfile`), with no image per plugin. `bin/test_image` copies the files that git tracks or would track, of the plugin's checkout and of Redmine Kit AWS's, into a folder mounted at `/src/plugins`, as `redmine_kit_aws_lambda/` and `redmine_kit_aws/`; the image's entrypoint copies them into Redmine's `plugins/`.

When the tests need the plugin as a gem by path (so that Bundler loads `boot/`), `bin/test_image` writes a `PluginGemfile` into the plugin's folder, which Redmine's Gemfile reads with the plugins' Gemfiles. Bundler then needs `redmine_kit_aws` by path too:

```ruby
gem 'redmine_kit_aws', path: '/redmine/plugins/redmine_kit_aws', require: false
gem 'redmine_kit_aws_lambda', path: '/redmine/plugins/redmine_kit_aws_lambda'
```

CI checks out `redmine-kit/redmine_aws` into `redmine_kit_aws/` and sets `REDMINE_KIT_AWS_DIR`. [Redmine Kit AWS Lambda](https://github.com/redmine-kit/redmine_aws_lambda) does all of this.

The plugins' CI also runs two jobs around the gem. `test (redmine_kit_aws release)` runs the tests with the newest `v0.*` tag of this plugin, the source of the published gem, as well as with its main; until the first release it only notes that there is none. `gem` runs `bin/test-gem`, which builds the plugin's gem and this plugin's, installs them into Redmine as the plugin's setup page says, links them into `plugins/` and boots Redmine with every file loaded (`zeitwerk:check`, and the production environment), so that a gem that misses a file fails before a version tag publishes it. This plugin's own `bin/test-gem` boots it both as the setup page installs it (not required by Bundler) and required early by Bundler.
