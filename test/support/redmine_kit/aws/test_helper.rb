# frozen_string_literal: true

module RedmineKit
  module Aws
    # Helpers for the tests of the Redmine Kit AWS plugins. A plugin's
    # test/test_helper.rb loads it after Redmine's test helper, from wherever
    # redmine_kit_aws is installed:
    #   require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit/aws/test_helper')
    # and includes it in its own test helper module or in a test class.
    module TestHelper
      # The region and credentials of clients in tests; AWS Emulator (with its
      # authentication off), LocalStack and moto accept any.
      TEST_REGION = 'us-east-1'

      def self.credentials
        ::Aws::Credentials.new('test', 'test')
      end

      # Runs the block with the environment variables set; nil unsets one.
      def with_env(values)
        saved = values.keys.index_with { |name| ENV.fetch(name, nil) }
        values.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
        yield
      ensure
        saved&.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
      end

      # Runs the block with RedmineKit::Aws.client_options merged with the options,
      # for example endpoint: to send every client built with RedmineKit::Aws.client
      # to AWS Emulator (or to LocalStack or moto where a plugin's testing docs
      # say so).
      def with_aws_client_options(**options)
        saved = RedmineKit::Aws.client_options
        RedmineKit::Aws.client_options = saved.merge(options)
        yield
      ensure
        RedmineKit::Aws.client_options = saved
      end

      # A client of the SDK class with response stubs (stub_responses), as in
      # the SDK's documentation: no stubs answers every call with empty data.
      def stub_aws_client(klass, **stubs)
        klass.new(stub_responses: stubs.presence || true, region: TEST_REGION, credentials: TestHelper.credentials)
      end
    end
  end
end
