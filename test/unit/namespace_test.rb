# frozen_string_literal: true

require_relative '../test_helper'
require 'fileutils'
require 'open3'
require 'tempfile'

module RedmineAws
  # The RedmineAws namespace is shared: the other Redmine AWS plugins put
  # their code under it (lib/redmine_aws/<plugin>.rb, with the names of the
  # AWS SDK: ses.rb defines RedmineAws::SES), and their boot/ files, which
  # Bundler loads before Rails, may define it before Redmine's code loader
  # (Zeitwerk) sets up. Checked in new processes, as at start-up, with a
  # plugin whose files are named as theirs (test/fixtures/redmine_aws_names).
  # One test, so that the plugin is in plugins/ for no other test.
  class NamespaceTest < ActiveSupport::TestCase
    FIXTURE = File.expand_path('../fixtures/redmine_aws_names', __dir__)
    PLUGIN = Rails.root.join('plugins/redmine_aws_names').to_s

    # What a boot/ file of another plugin does, after Bundler has loaded the
    # gems (bin/rails then loads them again, without effect).
    def early_boot
      <<~RUBY
        require 'bundler/setup'
        require #{File.join(Redmine::Plugin.find(:redmine_aws).directory, 'boot/redmine_aws/inflections').inspect}
        module RedmineAws
          module Early
          end
        end
      RUBY
    end

    # The constants of the fixture plugin's files, and a script that prints
    # the version, the tabs and their names.
    NAMES = %w[RedmineAws::SES RedmineAws::SES::Receiver RedmineAws::SQS RedmineAws::SSM
               RedmineAws::CostExplorer].freeze
    SCRIPT = [
      'print RedmineAws::VERSION, " ", RedmineAws::Admin.tabs.map(&:name).join(","), " ", ',
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
  end
end
