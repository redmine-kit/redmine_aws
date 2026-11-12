# frozen_string_literal: true

require_relative '../test_helper'

class AwsStatusControllerTest < Redmine::ControllerTest
  def setup
    @request.session[:user_id] = 1 # admin
  end

  # Runs the block as with Redmine AWS SSM, whose boot file defines
  # RedmineAws::SSM with the names of the parameters it read.
  def with_ssm(names)
    RedmineAws.const_set(:SSM, Module.new { define_singleton_method(:loaded) { names } })
    yield
  ensure
    RedmineAws.send(:remove_const, :SSM)
  end

  def test_index
    get :index

    assert_response :success
    assert_select 'h2', text: 'AWS'
    assert_select 'div.tabs a#tab-status.selected'
    # Values as Administration › Information shows them: a table.list without
    # a header row, not a settings form.
    assert_select 'table.list.values tr td.name', text: 'Redmine AWS'
    assert_select 'table.list.values tr', text: /\ARuby\s*#{Regexp.escape(RUBY_VERSION)}\z/
    assert_select 'table.list.values th', 0
    # Its stylesheet, once however many sections use the values table.
    assert_select 'head link[rel=stylesheet][href*="aws_values"]', 1
    assert_select 'div.box.tabular', 0
    assert_select 'p a[data-method=post]:not(.icon)', text: 'Test'
  end

  def test_the_parameters_read_by_redmine_aws_ssm
    with_ssm(%w[SECRET_KEY_BASE DATABASE_URL]) { get :index }

    assert_select 'h3', text: 'Parameter Store'
    assert_select 'table.list.values td.name code', text: 'SECRET_KEY_BASE'
    assert_select 'table.list.values td.name code', text: 'DATABASE_URL'
  end

  def test_no_parameters_read
    with_ssm([]) { get :index }

    assert_select 'h3', text: 'Parameter Store'
    assert_select 'p.nodata', text: 'No data to display'
  end

  def test_no_parameter_store_section_without_redmine_aws_ssm
    get :index

    assert_select 'h3', text: 'Parameter Store', count: 0
  end

  def test_registered_sections_are_shown_in_order
    RedmineAws::Admin.register_status_section(:early, partial: 'aws_status/versions', position: 5)
    get :index

    assert_response :success
    assert_select 'h3', text: 'Versions', count: 2
    assert_equal %w[early versions loaded_settings], RedmineAws::Admin.status_sections.map(&:name)
  ensure
    RedmineAws::Admin.instance_variable_get(:@status_sections).delete('early')
  end

  def test_check_runs_the_connection_checks
    post :check

    assert_response :success
    assert_select 'table.list.checks tr.ok td.name', text: 'Database'
    assert_select 'table.list.checks tr.ok td.value', text: /\APostgreSQL \d+(\.\d+)*\s+[\d,]+ ms\z/
    assert_select 'table.list.checks tr.ok td.value em.info', text: /\A[\d,]+ ms\z/
    assert_select 'table.list.checks th', 0
    assert_select 'table.list.checks tr.ok td.tick span.icon-ok'
  end

  # The page shows the class of the error, and the message goes only to the
  # log: a service's message may name hosts, accounts or resources.
  def test_a_failing_check_shows_the_error_class_and_logs_the_message
    message = 'User: arn:aws:iam::111122223333:user/redmine is not authorized'
    RedmineAws::Admin.register_check(:broken, label: :label_aws_failed) { raise IOError, message }
    log = capture_log { post :check }

    assert_response :success
    assert_select 'table.list.checks tr.failed td.value', text: /\AIOError\s+[\d,]+ ms\z/
    assert_select 'table.list.checks tr.failed td.tick span.icon-error'
    assert_not_includes response.body, message
    assert_includes log, "[redmine_aws] connection check broken failed: IOError: #{message}"
  ensure
    RedmineAws::Admin.instance_variable_get(:@checks).delete('broken')
  end

  def test_no_secret_values_on_the_page
    ENV['SECRET_KEY_BASE_FOR_TEST'] = 'not-shown-secret-value'
    get :index
    post :check

    assert_not_includes response.body, 'not-shown-secret-value'
    assert_not_includes response.body, Rails.application.secret_key_base
  ensure
    ENV.delete('SECRET_KEY_BASE_FOR_TEST')
  end

  def test_non_administrators_are_refused
    @request.session[:user_id] = 2
    get :index

    assert_response :forbidden
    post :check

    assert_response :forbidden
  end

  private

  # What Rails.logger writes while the block runs.
  def capture_log
    saved = Rails.logger
    log = StringIO.new
    Rails.logger = ActiveSupport::Logger.new(log)
    yield
    log.string
  ensure
    Rails.logger = saved
  end
end
