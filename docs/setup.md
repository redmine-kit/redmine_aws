# Setup

What a Redmine server needs to use Redmine Kit AWS: installation, configuration, AWS resources, IAM permissions and network access. Every Redmine Kit AWS plugin requires it, so it is installed with them. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later. Nothing in the plugin depends on the database; its tests run on PostgreSQL 16.
- Any server: on AWS Lambda, on EC2 or ECS, or elsewhere.

### Required plugins

None.

### Optional plugins

| Plugin | With it |
| --- | --- |
| [Redmine Kit AWS SSM](https://github.com/redmine-kit/redmine_aws_ssm) | the Parameter Store state on the Status tab |
| [Redmine Kit UI](https://github.com/redmine-kit/redmine_kit_ui) | the new UI's screen of the Status tab ([admin.md](admin.md#in-the-new-ui)) |
| [Redmine Kit Help](https://github.com/redmine-kit/redmine_help) | this plugin's help in the Help panel |

## Installation

1. Get the plugin into `plugins/redmine_kit_aws` of Redmine 7.0: the gem below, or a checkout of this repository in a folder named after the plugin's id, which differs from the repository's name (`git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_kit_aws`). The plugin has no gems of its own, so it needs no line in `Gemfile.local` for itself. With checkouts, the plugins that have a `boot/` file (Redmine Kit AWS Lambda, SES, SQS and SSM) are added to `Gemfile.local` by path, and then `redmine_kit_aws` is added by path too, once however many plugins are added (`gem 'redmine_kit_aws', path: 'plugins/redmine_kit_aws', require: false`; the setup of each plugin shows the lines).
2. Install the Redmine Kit AWS plugins that use it in `plugins/`, next to it. The order doesn't matter: at boot, Redmine stops and names `redmine_kit_aws` when it is missing ([Required plugins](#required-plugins)).
3. No migration is needed.

### Gem

`bin/release` publishes each version of the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`, [Releasing](#releasing)). The gem holds the run-time files (`init.rb`, `boot/`, `lib/`, `app/`, `assets/`, `config/`, `help/`, `LICENSE`) and `test/support/`; the plugin's `Gemfile` is not in it. The gems of the other Redmine Kit AWS plugins depend on it, so Bundler installs it with them. Redmine loads plugins only from `plugins/`, so the installed gem is linked there:

```sh
ln -s "$(bundle info --path redmine_kit_aws)" plugins/redmine_kit_aws
```

Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package (the setup of each plugin shows the `Gemfile.local` lines). Bundler can also install the plugin from this repository, which needs no token: `gem 'redmine_kit_aws', git: 'https://github.com/redmine-kit/redmine_aws.git', tag: 'v0.1.0', require: false`.

## Configuration

The plugin has no settings of its own. The AWS clients of the plugins read the credentials, the region and the endpoints as the AWS SDK does:

| Key | Description | Parameter |
| --- | --- | --- |
| `AWS_REGION` | The region of the AWS clients, unless a plugin sets its own | Set by Lambda. Elsewhere, `AWS_REGION` or `AWS_DEFAULT_REGION` |

To read settings and secrets from SSM Parameter Store at start-up, use [Redmine Kit AWS SSM](https://redmine-kit.github.io/redmine_aws_ssm/). With it installed, the "Status" tab shows the names of the parameters read.

## AWS resources

None.

## IAM permissions

The permissions the plugin needs, with an example policy, are in [iam.md](iam.md).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| The database | PostgreSQL (the database test on the "Status" tab) | A security group rule from the server to the database port |

## Tests

The tests are in `test/` and run with Redmine's standard mechanism, in Redmine 7.0.3 on PostgreSQL 16, in Apple container when it is installed and running, else in Docker (`CONTAINER_CLI=container` or `docker` chooses). At most two test runs of the redmine-kit repositories run at once on a machine (`TEST_SLOTS`); a run waits for a free slot. `bin/test` runs the plugin's tests with [Redmine Kit UI](https://github.com/redmine-kit/redmine_kit_ui) installed (from the checkout next to this one, `../redmine_kit_ui` at `HEAD`; `REDMINE_KIT_UI` and `REDMINE_KIT_UI_REF` choose another), then without it, then Redmine's own tests around the administration menu and the plugins, without it; CI checks out redmine_kit_ui next to the plugin with the token `REDMINE_KIT_UI_TOKEN`; `bin/test --redmine` runs every Redmine test with the plugin installed, as the CI does. CI runs the lint and the tests on Ruby 3.2 and 4.0; locally, `TEST_RUBY=3.2 bin/test` (or `bin/lint`) runs them on Ruby 3.2.

A run stops the service containers it started (it doesn't remove them) when it ends, whether the tests pass, fail or are interrupted. Containers that were running before the run, or that another run of this repository still uses, are left running. `KEEP_SERVICES=1` keeps them running after the run.

With `COVERAGE=1`, the plugin's tests also write the coverage of the plugin's own files (SimpleCov, Cobertura XML in `coverage/coverage.xml`) and run in one process. CI sets it on Ruby 4.0 and uploads the report to [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws) with the flag `plugin`. The upload authenticates with OIDC (`id-token: write`), so no token is stored as a secret. Codecov's statuses are informational and never fail a commit or a pull request (`codecov.yml`).

`bin/test-gem` checks the gem: it builds the gem from the checkout, installs it as [Gem](#gem) says, links it into `plugins/` and starts Redmine with every file loaded (`zeitwerk:check`, and the production environment, which loads them at start-up). CI runs it too, so a file missing from the gem fails before the other plugins or Serverless install it.

```sh
bin/test            # the plugin's tests with and without redmine_kit_ui, and Redmine's tests around them
bin/test --redmine  # with every Redmine test
COVERAGE=1 bin/test # with the coverage in coverage/coverage.xml
bin/test-gem        # the gem: built, installed, linked into plugins/, booted
bin/lint            # RuboCop
bin/screenshots     # the screenshots of admin.md
bin/services --down # stops PostgreSQL (and Chromium)
```

The new UI's module is checked in `frontend/` with Node.js (the version in `frontend/.nvmrc`); `.npmrc` has `ignore-scripts=true`, and `@redmine-kit/ui` and `@redmine-kit/plugin` come from the checkout of the ui repository next to this one (`../../ui/packages/…`):

```sh
cd frontend
npm install
npm run check       # type check, the components' tests (vitest), the build, kit-check-ui, the Storybook's build
npm run storybook   # the Storybook of the tab's states, on port 6008
```

The other plugins' tests load this plugin from a checkout next to theirs (`../redmine_kit_aws`, or the directory in `REDMINE_KIT_AWS_DIR`) ([api.md](api.md#tests-of-the-plugins)).

## Releasing

`bin/release` publishes the gem of the gemspec's version to Redmine Kit's registry on GitHub Packages, from a clean
`main` only: the version must be newer than the last tag `v<version>`, the required plugins must resolve from the
registry at their ranges (`config/dependencies.yml`), and `bin/lint`, `bin/test` and `bin/test-gem` must pass. It
pushes with the key `github` of `~/.gem/credentials` (`:github: Bearer <token>`, a token with `write:packages`) and
reads the registry with `BUNDLE_RUBYGEMS__PKG__GITHUB__COM`; no token goes into the repository or the output. It makes
the signed tag `v<version>` and prints the command that pushes it. Versions are semantic: a change that breaks a plugin
using this one raises the major version (the minor one before 1.0), and the ranges in the plugins that require it.

## To verify

Nothing.
