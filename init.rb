# frozen_string_literal: true

# Redmine runs this when it prepares the code, again on every reload. The
# other AWS plugins require this one and register their tabs and checks after
# it (Redmine loads plugins in alphabetical order).

# The constant names of the plugins' files (lib/redmine_kit_aws/ses.rb defines
# RedmineKitAws::SES), before the code loader names the files in RedmineKitAws.
require File.expand_path('boot/redmine_kit_aws/inflections', __dir__)

# Redmine's code loader (Zeitwerk) skips lib/redmine_kit_aws.rb when RedmineKitAws is
# already defined: another plugin's boot/ file, which Bundler loads before
# Rails, may define the namespace for its own constants (RedmineKitAws::SSM).
# The file is then loaded here.
require File.expand_path('lib/redmine_kit_aws', __dir__) unless defined?(RedmineKitAws::VERSION)

Redmine::Plugin.register :redmine_kit_aws do
  name 'Redmine Kit AWS'
  author 'Redmine Kit'
  description 'The AWS item of the administration menu, shared by the Redmine Kit AWS plugins'
  version RedmineKitAws::VERSION
  url 'https://github.com/redmine-kit/redmine_aws'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineKitAws.setup
