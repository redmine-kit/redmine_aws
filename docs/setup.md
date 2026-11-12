# Setup

What a Redmine server needs to use Redmine AWS: installation, configuration, AWS resources, IAM permissions and network access. Every Redmine AWS plugin requires it, so it is installed with them. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later. Nothing in the plugin depends on the database; its tests run on PostgreSQL 16.
- Any server: on AWS Lambda, on EC2 or ECS, or elsewhere.

## Installation

1. Get the plugin into `plugins/redmine_aws` of Redmine 7.0: the gem below, or a checkout of this repository. The plugin has no gems of its own, so it needs no line in `Gemfile.local` for itself. With checkouts, the plugins that have a `boot/` file (Redmine AWS Lambda, SES, SQS and SSM) are added to `Gemfile.local` by path, and then `redmine_aws` is added by path too, once however many plugins are added (`gem 'redmine_aws', path: 'plugins/redmine_aws', require: false`; the setup of each plugin shows the lines).
2. Install the Redmine AWS plugins that use it in `plugins/`, next to it. Redmine loads plugins in alphabetical order, so `redmine_aws` comes first; each of them checks that it is there (`requires_redmine_plugin :redmine_aws`).
3. No migration is needed.

### Gem

Each version tag (`v*`) publishes the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`; `.github/workflows/gem.yml`). The gem holds the run-time files (`init.rb`, `boot/`, `lib/`, `app/`, `assets/`, `config/`, `help/`, `LICENSE`) and `test/support/`; the plugin's `Gemfile` is not in it. The gems of the other Redmine AWS plugins depend on it, so Bundler installs it with them. Redmine loads plugins only from `plugins/`, so the installed gem is linked there:

```sh
ln -s "$(bundle info --path redmine_aws)" plugins/redmine_aws
```

Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package (the setup of each plugin shows the `Gemfile.local` lines).

## Configuration

The plugin has no settings of its own. The AWS clients of the plugins read the credentials, the region and the endpoints as the AWS SDK does:

| Key | Description | Parameter |
| --- | --- | --- |
| `AWS_REGION` | The region of the AWS clients, unless a plugin sets its own | Set by Lambda. Elsewhere, `AWS_REGION` or `AWS_DEFAULT_REGION` |

To read settings and secrets from SSM Parameter Store at start-up, use [Redmine AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/). With it installed, the "Status" tab shows the names of the parameters read.

## AWS resources

None.

## IAM permissions

The permissions the plugin needs, with an example policy, are in [iam.md](iam.md).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| The database | PostgreSQL (the database test on the "Status" tab) | A security group rule from the server to the database port |

## Tests

The tests are in `test/` and run with Redmine's standard mechanism, in Redmine 7.0.3 on PostgreSQL 16 in Docker. `bin/test` runs the plugin's tests, then Redmine's own tests around the administration menu and the plugins; `bin/test --redmine` runs every Redmine test with the plugin installed, as the CI does. CI runs the lint and the tests on Ruby 3.2 and 4.0; locally, `TEST_RUBY=3.2 bin/test` (or `bin/lint`) runs them on Ruby 3.2.

The plugin's tests also write the coverage of the plugin's own files (SimpleCov, Cobertura XML in `coverage/coverage.xml`), which CI uploads to [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws).

`bin/test-gem` checks the gem: it builds the gem from the checkout, installs it as [Gem](#gem) says, links it into `plugins/` and starts Redmine with every file loaded (`zeitwerk:check`, and the production environment, which loads them at start-up). CI runs it too, so a file missing from the gem fails before the other plugins or Serverless install it.

```sh
bin/test            # the plugin's tests and Redmine's tests around them
bin/test --redmine  # with every Redmine test
bin/test-gem        # the gem: built, installed, linked into plugins/, booted
bin/lint            # RuboCop
bin/screenshots     # the screenshots of admin.md
bin/services --down # stops PostgreSQL
```

The other plugins' tests load this plugin from a checkout next to theirs (`../redmine_aws`, or the directory in `REDMINE_AWS_DIR`) ([api.md](api.md#tests-of-the-plugins)).

## To verify

Nothing.
