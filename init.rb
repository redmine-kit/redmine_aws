# frozen_string_literal: true

# Redmine runs this when it prepares the code, again on every reload. The
# other AWS plugins require this one and register their tabs and checks after
# it (Redmine loads plugins in alphabetical order).

# The constant names of the plugins' files (lib/redmine_aws/ses.rb defines
# RedmineAws::SES), before the code loader names the files in RedmineAws.
require File.expand_path('boot/redmine_aws/inflections', __dir__)

# Redmine's code loader (Zeitwerk) skips lib/redmine_aws.rb when RedmineAws is
# already defined: another plugin's boot/ file, which Bundler loads before
# Rails, may define the namespace for its own constants (RedmineAws::SSM).
# The file is then loaded here.
require File.expand_path('lib/redmine_aws', __dir__) unless defined?(RedmineAws::VERSION)

Redmine::Plugin.register :redmine_aws do
  name 'Redmine AWS'
  author 'Redmine Kit'
  description 'The AWS item of the administration menu, shared by the Redmine AWS plugins'
  version RedmineAws::VERSION
  url 'https://github.com/redmine-kit/redmine_aws'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end

RedmineAws.setup
