# frozen_string_literal: true

require 'yaml'

# The plugin as a gem, published to GitHub Packages (.github/workflows/gem.yml).
# The gem holds the plugin's run-time files, so that the installed gem can be
# linked into Redmine's plugins/ (docs/setup.md#installation), and the test
# support of test/support/, which the other Redmine Kit AWS plugins' tests load.
# The plugin's Gemfile is not in it: Redmine's Gemfile would load it again.
# Redmine loads lib/ itself; with lib/ on the load path, code that runs before
# Rails can require 'redmine_kit/aws'.
Gem::Specification.new do |spec|
  spec.name = 'redmine_kit_aws'
  spec.version = File.read(File.join(__dir__, 'lib/redmine_kit/aws.rb'))[/VERSION = '([^']+)'/, 1]
  spec.summary = 'The administration menu shared by the Redmine Kit AWS plugins'
  spec.authors = ['Redmine Kit']
  spec.license = 'GPL-2.0-or-later'
  spec.homepage = 'https://github.com/redmine-kit/redmine_aws'
  # The Ruby versions of Redmine 7.0 (its Gemfile: ruby '>= 3.2.0', '< 4.1.0').
  spec.required_ruby_version = ['>= 3.2', '< 4.1']
  spec.files = Dir['{init.rb,LICENSE}', '{app,assets,boot,config,db,lib,help}/**/*', 'test/support/**/*']
  spec.require_paths = %w[boot lib]
  spec.metadata['github_repo'] = 'ssh://github.com/redmine-kit/redmine_aws'
  # The plugins it requires (config/dependencies.yml): installing the gem installs them.
  YAML.safe_load_file(File.join(__dir__, 'config/dependencies.yml'))['requires'].each do |name, range|
    spec.add_dependency name, range
  end
  spec.metadata['rubygems_mfa_required'] = 'true'
end
