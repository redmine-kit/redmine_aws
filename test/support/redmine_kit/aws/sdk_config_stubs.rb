# frozen_string_literal: true

begin
  require 'aws-sdk-core'
rescue LoadError
  # The tests of a plugin without the AWS SDK (redmine_kit_aws_lambda's): nothing to fix.
end

module RedmineKit
  module Aws
    # Lets SDK clients with response stubs (stub_responses) work in tests that
    # load Mocha, as Redmine's test helper does. Since aws-sdk-core 3.270.0
    # (aws/aws-sdk-ruby#3492), a client's configuration answers its options
    # through method_missing, so that Mocha's public Object#stubs answers the
    # option `stubs` instead: a client built with a Hash of stubs, or any call
    # on a stubbed client, raises "wrong number of arguments (given 0,
    # expected 1)" (aws/aws-sdk-ruby#3501, open on 2026-11-19). The reader
    # here returns the option again. Remove it when an SDK release fixes
    # #3501: test/unit/test_helper_test.rb then passes without it.
    module SdkConfigStubs
      def stubs(*args, &)
        return super unless args.empty? && !block_given? && members.include?(:stubs)

        self[:stubs]
      end
    end
  end
end

if defined?(Seahorse::Client::Configuration::DynamicStruct)
  Seahorse::Client::Configuration::DynamicStruct.prepend(RedmineKit::Aws::SdkConfigStubs)
end
