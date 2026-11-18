# frozen_string_literal: true

require_relative '../test_helper'
require 'fileutils'
require 'open3'
require 'tempfile'

module RedmineKit
  module Aws
    # The RedmineKit::Aws namespace is shared: the other Redmine Kit AWS plugins
    # put their code under it, from their own lib/ (lib/redmine_kit/aws/ses.rb
    # defines RedmineKit::Aws::Ses), and their boot/ files, which Bundler loads
    # before Rails, may define it before Redmine's code loader (Zeitwerk) sets
    # up. RedmineKit above it belongs to no plugin. Checked in new processes, as
    # at start-up, with a plugin whose files are named as theirs
    # (test/fixtures/redmine_kit_aws_names), in plugins/ for that test only.
    class NamespaceTest < ActiveSupport::TestCase
      FIXTURE = File.expand_path('../fixtures/redmine_kit_aws_names', __dir__)
      PLUGIN = Rails.root.join('plugins/redmine_kit_aws_names').to_s

      # What a boot/ file of another plugin does, after Bundler has loaded the
      # gems (bin/rails then loads them again, without effect).
      def early_boot
        <<~RUBY
          require 'bundler/setup'
          module RedmineKit
            module Aws
              module Early
              end
            end
          end
        RUBY
      end

      # The constants of the fixture plugin's files, and a script that prints
      # the version, the tabs and their names.
      NAMES = %w[RedmineKit::Aws::Ses RedmineKit::Aws::Ses::Receiver RedmineKit::Aws::Sqs RedmineKit::Aws::Ssm
                 RedmineKit::Aws::Costexplorer].freeze
      SCRIPT = [
        'print RedmineKit::Aws::VERSION, " ", RedmineKit::Aws::Admin.tabs.map(&:name).join(","), " ", ',
        "[#{NAMES.join(', ')}].map(&:name).join(\",\")"
      ].join.freeze

      # bin/rails with the arguments in a new process; early: with the early
      # boot file required first. Returns the last line of the output.
      def rails(*, early: false)
        Tempfile.create(['early', '.rb']) do |file|
          file.write(early_boot)
          file.flush
          out, status = Open3.capture2e(rails_env(early ? file.path : nil), 'bin/rails', *, chdir: Rails.root.to_s)
          assert status.success?, out
          out.lines.last.to_s.strip
        end
      end

      def rails_env(early_file)
        env = { 'RAILS_ENV' => 'test' }
        env['RUBYOPT'] = "#{ENV.fetch('RUBYOPT', nil)} -r#{early_file}".strip if early_file
        env
      end

      def test_the_namespace_loads_from_every_plugin
        FileUtils.cp_r(FIXTURE, PLUGIN)
        [false, true].each do |early|
          assert_equal 'All is good!', rails('zeitwerk:check', early: early), "early: #{early}"
          assert_equal "#{VERSION} status #{NAMES.join(',')}", rails('runner', SCRIPT, early: early), "early: #{early}"
        end
      ensure
        FileUtils.rm_rf(PLUGIN)
      end

      # RedmineKit is the namespace of every plugin of the organization; the
      # code loader makes it from their lib/redmine_kit/ directories. A plugin
      # with lib/redmine_kit.rb would own it, and the code loader would skip
      # every other plugin's file of the same name.
      def test_no_plugin_file_defines_redmine_kit
        dir = Redmine::Plugin.find(:redmine_kit_aws).directory

        assert_not File.exist?(File.join(dir, 'lib/redmine_kit.rb')), 'lib/redmine_kit.rb defines RedmineKit'
      end
    end
  end
end
