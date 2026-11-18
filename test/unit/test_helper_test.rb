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
    end
  end
end
