# frozen_string_literal: true

require_relative '../test_helper'

module RedmineKitAws
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
      RedmineKitAws.client_options = nil
    end

    def test_without_settings_the_sdk_decides
      assert_nil RedmineKitAws.region
      assert_equal({}, RedmineKitAws.client(FakeClient).options)
    end

    def test_the_region_from_the_environment
      ENV['AWS_DEFAULT_REGION'] = 'eu-west-1'

      assert_equal 'eu-west-1', RedmineKitAws.region
      ENV['AWS_REGION'] = 'ap-northeast-1'

      assert_equal 'ap-northeast-1', RedmineKitAws.region
      assert_equal({ region: 'ap-northeast-1' }, RedmineKitAws.client(FakeClient).options)
    end

    def test_the_plugin_options_over_the_region
      ENV['AWS_REGION'] = 'ap-northeast-1'

      assert_equal({ region: 'us-east-1', retry_limit: 0 },
                   RedmineKitAws.client(FakeClient, region: 'us-east-1', retry_limit: 0).options)
    end

    def test_client_options_over_everything
      ENV['AWS_REGION'] = 'ap-northeast-1'
      RedmineKitAws.client_options = { endpoint: 'https://127.0.0.1:9297', region: 'us-east-1' }

      assert_equal({ region: 'us-east-1', retry_limit: 0, endpoint: 'https://127.0.0.1:9297' },
                   RedmineKitAws.client(FakeClient, region: 'eu-west-1', retry_limit: 0).options)
    end

    def test_env_true
      ENV['FLAG'] = ' True '

      assert RedmineKitAws.env_true?('FLAG')
      ENV['FLAG'] = '1'

      assert_not RedmineKitAws.env_true?('FLAG')
      ENV.delete('FLAG')

      assert_not RedmineKitAws.env_true?('FLAG')
    end
  end
end
