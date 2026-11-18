# frozen_string_literal: true

# Coverage of the plugin's own files (bin/test sets PLUGIN_COVERAGE for the
# plugin's tests), written as Cobertura XML to coverage/ for Codecov. It starts
# before Redmine loads, so that lib/ and app/ are counted.
if ENV['PLUGIN_COVERAGE'] && !(defined?(SimpleCov) && SimpleCov.running)
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.start do
    root File.expand_path('..', __dir__)
    # Every file of the plugin, so that a file no test loads shows as 0%. The
    # glob is absolute: SimpleCov reads it from the current directory
    # (Redmine's when bin/rails test runs), not from root.
    track_files "#{root}/{init.rb,app/**/*.rb,boot/**/*.rb,lib/**/*.rb}"
    add_filter '/test/'
    enable_coverage :branch
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end

require File.expand_path('../../../test/test_helper', __dir__)
require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit/aws/test_helper')
