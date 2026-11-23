# frozen_string_literal: true

module RedmineKit
  module Aws
    # What the "Status" tab shows (docs/admin.md#status).
    # No secret values: only names.
    class Status
      def versions
        plugins = Redmine::Plugin.all.select { |plugin| self.class.family?(plugin.id) }
        [['Redmine', Redmine::VERSION.to_s], ['Ruby', RUBY_VERSION], ['Rails', Rails.version]] +
          plugins.map { |plugin| [plugin.name.to_s, plugin.version.to_s] }
      end

      # Names read from SSM Parameter Store at start-up, when Redmine Kit AWS SSM is
      # installed (its boot file defines RedmineKit::Aws::Ssm); nil otherwise.
      def loaded_settings
        RedmineKit::Aws::Ssm.loaded if defined?(RedmineKit::Aws::Ssm) && RedmineKit::Aws::Ssm.respond_to?(:loaded)
      end

      # The sections of the Status tab in their order (Admin.register_status_section),
      # one place for both UIs: { name:, label:, rows: }, the heading in the
      # user's language. A section whose block returns nil is left out. view:
      # the view whose helpers the blocks use.
      def sections(view)
        Admin.status_sections.filter_map do |section|
          rows = section.rows.call(view, self)
          { name: section.name, label: view.l(section.label), rows: rows } unless rows.nil?
        end
      end

      # Whether a plugin id is of the family: redmine_kit_aws itself or one of
      # its parts, redmine_kit_aws_<part>. Not every id that starts with
      # redmine_kit_aws: another plugin may be named redmine_kit_awsome.
      def self.family?(id)
        id.to_s == 'redmine_kit_aws' || id.to_s.start_with?('redmine_kit_aws_')
      end

      # A new connection to the configured database, closed afterwards, so that
      # the check shows whether a connection can be opened now.
      def self.database_check
        db_config = ActiveRecord::Base.connection_db_config
        adapter = db_config.adapter_class.new(db_config.configuration_hash)
        begin
          "#{adapter.adapter_name} #{database_version(adapter)}"
        ensure
          adapter.disconnect!
        end
      end

      # The server's version ("16.4"), which also shows that a query runs.
      def self.database_version(adapter)
        sql = case adapter.adapter_name
              when /postg/i then 'SHOW server_version'
              when /sqlite/i then 'SELECT sqlite_version()'
              else 'SELECT VERSION()'
              end
        adapter.select_value(sql).to_s.split.first
      end
    end
  end
end
