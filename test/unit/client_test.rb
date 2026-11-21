# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKit
  module Aws
    class ClientTest < ActiveSupport::TestCase
      # Stands for an SDK client class: keeps the options it is built with.
      FakeClient = Struct.new(:options) do
        def initialize(**options)
          super(options)
        end
      end

      def setup
        @saved = %w[AWS_REGION AWS_DEFAULT_REGION FLAG].index_with { |name| ENV.fetch(name, nil) }
        ENV.delete('AWS_REGION')
        ENV.delete('AWS_DEFAULT_REGION')
      end

      def teardown
        @saved.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
        RedmineKit::Aws.client_options = nil
      end

      def test_without_settings_the_sdk_decides
        assert_nil RedmineKit::Aws.region
        assert_equal({}, RedmineKit::Aws.client(FakeClient).options)
      end

      def test_the_region_from_the_environment
        ENV['AWS_DEFAULT_REGION'] = 'eu-west-1'

        assert_equal 'eu-west-1', RedmineKit::Aws.region
        ENV['AWS_REGION'] = 'ap-northeast-1'

        assert_equal 'ap-northeast-1', RedmineKit::Aws.region
        assert_equal({ region: 'ap-northeast-1' }, RedmineKit::Aws.client(FakeClient).options)
      end

      def test_the_plugin_options_over_the_region
        ENV['AWS_REGION'] = 'ap-northeast-1'

        assert_equal({ region: 'us-east-1', retry_limit: 0 },
                     RedmineKit::Aws.client(FakeClient, region: 'us-east-1', retry_limit: 0).options)
      end

      # The SDK takes credentials: nil or region: nil as given, instead of its
      # own chain, and then fails to sign: such options are left out.
      def test_nil_options_are_left_out
        ENV['AWS_REGION'] = 'ap-northeast-1'

        assert_equal({ region: 'ap-northeast-1', retry_limit: 2 },
                     RedmineKit::Aws.client(FakeClient, region: nil, credentials: nil, retry_limit: 2).options)
      end

      def test_client_options_over_everything
        ENV['AWS_REGION'] = 'ap-northeast-1'
        RedmineKit::Aws.client_options = { endpoint: 'https://127.0.0.1:9297', region: 'us-east-1' }

        assert_equal({ region: 'us-east-1', retry_limit: 0, endpoint: 'https://127.0.0.1:9297' },
                     RedmineKit::Aws.client(FakeClient, region: 'eu-west-1', retry_limit: 0).options)
      end

      def test_env_true
        ENV['FLAG'] = ' True '

        assert RedmineKit::Aws.env_true?('FLAG')
        ENV['FLAG'] = '1'

        assert_not RedmineKit::Aws.env_true?('FLAG')
        ENV.delete('FLAG')

        assert_not RedmineKit::Aws.env_true?('FLAG')
      end
    end
  end
end
