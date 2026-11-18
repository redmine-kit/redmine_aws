# frozen_string_literal: true

module RedmineKitAws
  # The "AWS" item of Redmine's administration menu (docs/admin.md#the-aws-menu).
  # Each Redmine Kit AWS plugin registers its tab and its connection check here
  # from its init.rb; the first tab adds the menu item.
  module Admin
    Tab = Struct.new(:name, :label, :url, :position, keyword_init: true)
    Check = Struct.new(:name, :label, :run, keyword_init: true)
    Result = Struct.new(:name, :label, :ok, :detail, :milliseconds, keyword_init: true)
    Section = Struct.new(:name, :partial, :position, keyword_init: true)

    @tabs = {}
    @checks = {}
    @status_sections = {}

    class << self
      # url: a route hash; label: an i18n key; position: the order of the tabs.
      def register_tab(name, label:, url:, position:)
        @tabs[name.to_s] = Tab.new(name: name.to_s, label: label, url: url, position: position)
        add_menu_item
      end

      def tabs
        @tabs.values.sort_by(&:position)
      end

      # A light call that shows whether a service can be reached; the block
      # returns a short text, or raises.
      def register_check(name, label:, &run)
        @checks[name.to_s] = Check.new(name: name.to_s, label: label, run: run)
      end

      def checks
        @checks.values
      end

      # A part of the Status tab: a view partial, rendered with the local
      # status (a RedmineKitAws::Status), at a position among the tab's own parts
      # (Versions 20, Parameter Store 30). The connection test comes last.
      def register_status_section(name, partial:, position:)
        @status_sections[name.to_s] = Section.new(name: name.to_s, partial: partial, position: position)
      end

      def status_sections
        @status_sections.values.sort_by(&:position)
      end

      # Whether the routes have the menu's entry. Redmine draws plugin routes
      # from its plugin directory; when routes are drawn without it (some of
      # Redmine's own tests change the directory), the menu item is hidden
      # instead of breaking every administration page.
      def routed?
        Rails.application.routes.routes.any? { |route| route.defaults[:controller] == 'aws_admin' }
      end

      # The connection test of the Status tab (docs/admin.md#status).
      def run_checks
        checks.map { |check| run_check(check) }
      end

      private

      # The result of one check, with the time it took.
      def run_check(check)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ok, detail = call_check(check)
        milliseconds = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
        Result.new(name: check.name, label: check.label, ok: ok, detail: detail, milliseconds: milliseconds)
      end

      # A failed check shows the class of the error (Aws::S3::Errors::Forbidden,
      # PG::ConnectionBad), never its message, which comes from the service
      # and may name hosts, accounts or resources; the message goes to the log.
      # Any StandardError: a check calls another plugin's code and a service,
      # and one failing check must not keep the page from opening.
      def call_check(check)
        [true, check.run.call.to_s]
      rescue StandardError => e
        Rails.logger.error "[redmine_kit_aws] connection check #{check.name} failed: #{e.class}: #{e.message}"
        [false, e.class.name]
      end

      def add_menu_item
        Redmine::MenuManager.map(:admin_menu) do |menu|
          next if menu.exists?(:aws)

          menu.push :aws, { controller: 'aws_admin', action: 'index' },
                    caption: :label_aws, icon: 'server-authentication',
                    html: { class: 'icon icon-server-authentication' },
                    if: ->(_project) { RedmineKitAws::Admin.routed? }
        end
      end
    end
  end
end
