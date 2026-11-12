# frozen_string_literal: true

require_relative '../test_helper'

module RedmineAws
  class TestHelperTest < ActiveSupport::TestCase
    include RedmineAws::TestHelper

    def test_with_env_sets_and_restores
      ENV['REDMINE_AWS_TEST_A'] = 'before'
      with_env('REDMINE_AWS_TEST_A' => nil, 'REDMINE_AWS_TEST_B' => 'set') do
        assert_nil ENV.fetch('REDMINE_AWS_TEST_A', nil)
        assert_equal 'set', ENV.fetch('REDMINE_AWS_TEST_B', nil)
      end

      assert_equal 'before', ENV.fetch('REDMINE_AWS_TEST_A', nil)
      assert_nil ENV.fetch('REDMINE_AWS_TEST_B', nil)
    ensure
      ENV.delete('REDMINE_AWS_TEST_A')
    end

    def test_with_aws_client_options_merges_and_restores
      RedmineAws.client_options = { region: 'us-east-1' }
      with_aws_client_options(endpoint: 'http://moto:5000') do
        assert_equal({ region: 'us-east-1', endpoint: 'http://moto:5000' }, RedmineAws.client_options)
      end

      assert_equal({ region: 'us-east-1' }, RedmineAws.client_options)
    ensure
      RedmineAws.client_options = nil
    end
  end
end
