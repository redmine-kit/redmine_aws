# frozen_string_literal: true

# What the Redmine Kit AWS plugins share (docs/README.md): the "AWS" item of the
# administration menu with its tabs and connection checks (Admin), the Status
# tab, and the settings of the AWS clients. It works on any server and calls
# no AWS API itself. RedmineKit, the organization's namespace, belongs to no
# plugin: no plugin has lib/redmine_kit.rb, and the code loader makes it from
# the plugins' lib/redmine_kit/ directories.
module RedmineKit
  module Aws
    VERSION = '0.1.0'

    class << self
      # Called from init.rb, on every code reload.
      def setup
        Admin.register_tab(:status, label: :label_aws_status, url: { controller: 'aws_status', action: 'index' },
                                    position: 10)
        Admin.register_status_section(:versions, label: :label_aws_versions, position: 20) do |_view, status|
          status.versions.map { |name, version| { name: name, value: version } }
        end
        Admin.register_status_section(:loaded_settings, label: :label_aws_loaded_settings,
                                                        position: 30) do |_view, status|
          status.loaded_settings&.map { |name| { name: name, code: true } }
        end
        Admin.register_check(:database, label: :label_aws_check_database) { Status.database_check }
      end

      # Options that every AWS client built with RedmineKit::Aws.client gets, over
      # the SDK's own settings. Empty unless set: the SDK then reads the
      # credentials, the region and the endpoints from the environment and the
      # instance or function role, as usual (AWS_REGION, AWS_ENDPOINT_URL,
      # AWS_ENDPOINT_URL_<SERVICE>). Tests set it to send every plugin's
      # requests to AWS Emulator (endpoint:, credentials:; LocalStack or moto
      # only where a plugin's testing docs say so), or to SDK stubs
      # (stub_responses:) for errors and states that can't be set up otherwise.
      attr_writer :client_options

      def client_options
        @client_options ||= {}
      end

      # The region of the AWS clients: AWS_REGION, then AWS_DEFAULT_REGION; nil
      # when neither is set.
      def region
        ENV['AWS_REGION'].presence || ENV.fetch('AWS_DEFAULT_REGION', nil).presence
      end

      # A client of an AWS service, such as RedmineKit::Aws.client(Aws::S3::Client).
      # The options given here (a region of the plugin's own, timeouts) come
      # before client_options, so that tests can replace them. An option given
      # as nil is left out, because the SDK takes an explicit nil (credentials:
      # nil, region: nil) instead of its own chain and then fails to sign.
      def client(klass, **options)
        defaults = region ? { region: region } : {}
        klass.new(**defaults, **options.compact, **client_options)
      end

      # Whether an environment variable that turns something on is true
      # (true, TRUE or True, with spaces around ignored).
      def env_true?(name)
        ENV.fetch(name, '').strip.casecmp?('true')
      end
    end
  end
end
