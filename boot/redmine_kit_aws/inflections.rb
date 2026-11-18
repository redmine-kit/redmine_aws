# frozen_string_literal: true

# The constant names of the Redmine Kit AWS plugins' files under lib/redmine_kit_aws/,
# spelled as the AWS SDK for Ruby spells the services
# (docs/api.md#namespace-and-files): lib/redmine_kit_aws/ses.rb defines
# RedmineKitAws::SES. init.rb loads this file; a plugin whose boot/ file defines
# anything under RedmineKitAws requires it first ('redmine_kit_aws/inflections'),
# because the code loader then names the files under lib/redmine_kit_aws/ while it
# sets up, before any init.rb runs.
#
# The names go to Rails' code loaders in the before_initialize hook (at once
# when the hook has run already). Redmine's config/initializers/zeitwerk.rb
# then gives each loader a new inflector (loader.inflector = RedmineInflector.new),
# still before the loaders set up, which would drop the names. So each loader
# gets a module prepended to its singleton class that wraps
# Zeitwerk::Loader#inflector= (Zeitwerk's attribute writer): it calls super and
# adds the names to the inflector given. Zeitwerk and Rails have no hook
# between that assignment and the setup (on_setup runs after the loaders have
# named the files). test/unit/namespace_test.rb fails without it.
require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:before_initialize) do
  names = { 'ses' => 'SES', 'sqs' => 'SQS', 'ssm' => 'SSM', 'costexplorer' => 'CostExplorer' }.freeze
  keep_names = Module.new do
    define_method(:inflector=) do |inflector|
      super(inflector)
      inflector.inflect(names)
    end
  end
  Rails.autoloaders.each do |loader|
    loader.singleton_class.prepend(keep_names)
    loader.inflector.inflect(names)
  end
end
