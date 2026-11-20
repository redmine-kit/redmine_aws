# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Aws
    class TestHelperTest < ActiveSupport::TestCase
      include RedmineKit::Aws::TestHelper

      def test_with_env_sets_and_restores
        ENV['REDMINE_KIT_AWS_TEST_A'] = 'before'
        with_env('REDMINE_KIT_AWS_TEST_A' => nil, 'REDMINE_KIT_AWS_TEST_B' => 'set') do
          assert_nil ENV.fetch('REDMINE_KIT_AWS_TEST_A', nil)
          assert_equal 'set', ENV.fetch('REDMINE_KIT_AWS_TEST_B', nil)
        end

        assert_equal 'before', ENV.fetch('REDMINE_KIT_AWS_TEST_A', nil)
        assert_nil ENV.fetch('REDMINE_KIT_AWS_TEST_B', nil)
      ensure
        ENV.delete('REDMINE_KIT_AWS_TEST_A')
      end

      def test_with_aws_client_options_merges_and_restores
        RedmineKit::Aws.client_options = { region: 'us-east-1' }
        with_aws_client_options(endpoint: 'https://127.0.0.1:9297') do
          assert_equal({ region: 'us-east-1', endpoint: 'https://127.0.0.1:9297' }, RedmineKit::Aws.client_options)
        end

        assert_equal({ region: 'us-east-1' }, RedmineKit::Aws.client_options)
      ensure
        RedmineKit::Aws.client_options = nil
      end

      # Redmine's test helper loads Mocha, whose Object#stubs shadowed the
      # SDK's option of the same name (SdkConfigStubs): the client failed to
      # build with stubs and failed on every call.
      def test_stub_aws_client_answers_with_the_stubs_under_mocha
        assert_respond_to Object.new, :stubs, 'Mocha is loaded'

        client = stub_aws_client(::Aws::STS::Client, get_caller_identity: { account: '123456789012' })

        assert_equal '123456789012', client.get_caller_identity.account
        assert_equal [:get_caller_identity], client.api_requests.pluck(:operation_name)
      end

      # The SDK's stub data: placeholder values of the response's shape.
      def test_stub_aws_client_without_stubs_answers_with_the_sdks_stub_data
        client = stub_aws_client(::Aws::STS::Client)

        assert_kind_of String, client.get_caller_identity.account
        assert_equal TEST_REGION, client.config.region
      end
    end
  end
end
