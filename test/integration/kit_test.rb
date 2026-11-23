# frozen_string_literal: true

require_relative '../test_helper'

# The plugin in Redmine Kit's new UI (redmine_kit_ui, installed by bin/test's
# first run): the manifest it takes, the screen listed to system
# administrators only, and the Status tab's JSON of the browser's session
# (kit requests: the session and the CSRF token).
class AwsKitTest < Redmine::IntegrationTest
  include RedmineKit::Ui::TestHelper if Redmine::Plugin.installed?(:redmine_kit_ui)

  def setup
    unless Redmine::Plugin.installed?(:redmine_kit_ui)
      skip 'redmine_kit_ui is not installed (bin/test runs these with it)'
    end
    User.current = nil
  end

  def teardown
    ActionController::Base.allow_forgery_protection = false
  end

  # Runs the block as with Redmine Kit AWS SSM, whose boot file defines
  # RedmineKit::Aws::Ssm with the names of the parameters it read.
  def with_ssm(names)
    RedmineKit::Aws.const_set(:Ssm, Module.new { define_singleton_method(:loaded) { names } })
    yield
  ensure
    RedmineKit::Aws.send(:remove_const, :Ssm)
  end

  test 'redmine_kit_ui takes the manifest: the Status tab of the page AWS' do
    manifest = assert_kit_manifest(:redmine_kit_aws)
    screen = manifest.screens.sole
    assert_equal({ path: '/admin/aws/status', component: 'AwsStatus', layout: 'admin', menu_item: 'aws',
                   tab: 'label_aws_status', position: 10 },
                 screen.slice(:path, :component, :layout, :menu_item, :tab, :position))
  end

  test 'the screen is listed to system administrators only' do
    log_user('admin', 'admin')
    assert_equal %w[AwsStatus], kit_bootstrap_extension(:redmine_kit_aws)['screens'].pluck('component')
    reset!
    log_user('jsmith', 'jsmith')
    assert_nil kit_bootstrap_extension(:redmine_kit_aws)
  end

  test "the tab's values: the sections in their order, their headings in the user's language, names only" do
    headers = kit_session('admin', 'admin')
    with_ssm(%w[SECRET_KEY_BASE DATABASE_URL]) { get '/admin/aws/status.json', headers: headers }
    assert_response :success
    sections = response.parsed_body['sections']
    assert_equal %w[versions loaded_settings], sections.pluck('name')
    assert_equal ['Versions', 'Parameter Store'], sections.pluck('label')
    versions = sections.first['rows']
    assert_equal({ 'name' => 'Ruby', 'value' => RUBY_VERSION }, versions.detect { |row| row['name'] == 'Ruby' })
    assert_includes versions.pluck('name'), 'Redmine Kit AWS'
    assert_equal [{ 'name' => 'SECRET_KEY_BASE', 'code' => true }, { 'name' => 'DATABASE_URL', 'code' => true }],
                 sections.last['rows']
    assert_not_includes response.body, Rails.application.secret_key_base
  end

  test 'without Redmine Kit AWS SSM there is no Parameter Store; a registered section in its place' do
    RedmineKit::Aws::Admin.register_status_section(:early, label: :label_aws_status, position: 5) do |view, _status|
      [{ name: view.l(:label_aws_ok), value: view.format_object(true), note: 'REDMINE_ROLE' }]
    end
    get '/admin/aws/status.json', headers: kit_session('admin', 'admin')
    sections = response.parsed_body['sections']
    assert_equal %w[early versions], sections.pluck('name')
    assert_equal [{ 'name' => 'OK', 'value' => 'Yes', 'note' => 'REDMINE_ROLE' }], sections.first['rows']
  ensure
    RedmineKit::Aws::Admin.instance_variable_get(:@status_sections).delete('early')
  end

  test "the connection test: each check's name, state, detail and time, formatted by Redmine's helpers" do
    headers = kit_session('admin', 'admin')
    post '/admin/aws/status/check.json', headers: headers, as: :json
    assert_response :success
    database = response.parsed_body['results'].detect { |row| row['name'] == 'Database' }
    assert database['ok']
    assert_match(/\APostgreSQL \d+(\.\d+)*\z/, database['value'])
    assert_match(/\A[\d,]+ ms\z/, database['note'])
  end

  test 'a failing check gives the class of its error, never its message' do
    message = 'User: arn:aws:iam::111122223333:user/redmine is not authorized'
    RedmineKit::Aws::Admin.register_check(:broken, label: :label_aws_failed) { raise IOError, message }
    post '/admin/aws/status/check.json', headers: kit_session('admin', 'admin'), as: :json
    broken = response.parsed_body['results'].detect { |row| row['name'] == 'Failed' }
    assert_equal [false, 'IOError'], broken.values_at('ok', 'value')
    assert_not_includes response.body, message
  ensure
    RedmineKit::Aws::Admin.instance_variable_get(:@checks).delete('broken')
  end

  test 'the connection test needs the CSRF token' do
    headers = kit_session('admin', 'admin')
    post '/admin/aws/status/check.json', headers: headers.except('X-CSRF-Token'), as: :json
    assert_response 422
    assert_nil response.parsed_body['results']
  end

  test 'others than system administrators are refused' do
    headers = kit_session('jsmith')
    get '/admin/aws/status.json', headers: headers
    assert_response :forbidden
    post '/admin/aws/status/check.json', headers: headers, as: :json
    assert_response :forbidden
  end

  test 'a .json request without the kit header has no session: Redmine refuses it' do
    log_user('admin', 'admin')
    get '/admin/aws/status.json'
    assert_includes [401, 403], response.status
    assert_not_includes response.body, 'sections'
  end
end
