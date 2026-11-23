# frozen_string_literal: true

require_relative '../test_helper'

# The sections the plugins register on the Status tab (register_status_section),
# on Redmine's page: values (a label and rows), in their order.
class AwsStatusSectionsTest < Redmine::ControllerTest
  tests AwsStatusController

  SECTIONS = %w[early late empty hidden].freeze

  def setup
    @request.session[:user_id] = 1 # admin
    register
  end

  def teardown
    SECTIONS.each { |name| RedmineKit::Aws::Admin.instance_variable_get(:@status_sections).delete(name) }
  end

  def test_registered_sections_are_shown_in_order
    get :index

    assert_response :success
    assert_equal ['Status', 'Versions', 'OK', 'Failed', 'Connection test'],
                 css_select('#content h3').map(&:text)
  end

  def test_rows_are_formatted_by_the_block_with_the_view
    get :index

    assert_select 'table.list.values tr', text: /\AOK\s*Yes\s*REDMINE_ROLE\z/
    assert_select 'table.list.values td.value em.info', text: 'REDMINE_ROLE'
  end

  def test_a_section_without_rows_says_no_data
    get :index

    assert_select 'h3 + p.nodata', text: 'No data to display'
  end

  private

  # A section before Versions, one after Parameter Store, one without rows and
  # one left out (its block returns nil).
  def register
    admin = RedmineKit::Aws::Admin
    admin.register_status_section(:early, label: :label_aws_status, position: 5) do |view, _status|
      [{ name: view.l(:label_aws_ok), value: view.format_object(true), note: 'REDMINE_ROLE' }]
    end
    admin.register_status_section(:late, label: :label_aws_ok, position: 40) { [{ name: 'Late', value: 'X' }] }
    admin.register_status_section(:empty, label: :label_aws_failed, position: 50) { [] }
    admin.register_status_section(:hidden, label: :label_aws_failed, position: 60) { nil }
  end
end
