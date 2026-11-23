# frozen_string_literal: true

# The plugins this one requires (config/dependencies.yml): without one,
# Redmine stops here and names it.
load File.expand_path('config/dependencies.rb', __dir__)

# Redmine runs this when it prepares the code, again on every reload. The
# other AWS plugins require this one and register their tabs and checks after
# it (Redmine loads plugins in alphabetical order).

# Redmine's code loader (Zeitwerk) skips lib/redmine_kit/aws.rb when
# RedmineKit::Aws is already defined: another plugin's boot/ file, which
# Bundler loads before Rails, may define the namespace for its own constants
# (RedmineKit::Aws::Ssm). The file is then loaded here.
require File.expand_path('lib/redmine_kit/aws', __dir__) unless defined?(RedmineKit::Aws::VERSION)

Redmine::Plugin.register :redmine_kit_aws do
  name 'Redmine Kit AWS'
  author 'Redmine Kit'
  description 'The administration menu shared by the Redmine Kit AWS plugins'
  version RedmineKit::Aws::VERSION
  url 'https://github.com/redmine-kit/redmine_aws'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineKit::Aws.setup
