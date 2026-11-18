# frozen_string_literal: true

require_relative '../test_helper'

class AwsAdminControllerTest < Redmine::ControllerTest
  def test_index_opens_the_first_tab
    @request.session[:user_id] = 1
    get :index

    assert_redirected_to '/admin/aws/status'
  end

  def test_non_administrators_are_refused
    @request.session[:user_id] = 2
    get :index

    assert_response :forbidden
  end

  def test_one_menu_item
    items = Redmine::MenuManager.items(:admin_menu).children.select { |item| item.name == :aws }

    assert_equal 1, items.size
  end

  def test_registering_again_keeps_one_menu_item
    url = { controller: 'aws_status', action: 'index' }
    RedmineKitAws::Admin.register_tab(:extra, label: :label_aws_status, url: url, position: 99)
    items = Redmine::MenuManager.items(:admin_menu).children.select { |item| item.name == :aws }

    assert_equal 1, items.size
    assert_equal %w[status extra], RedmineKitAws::Admin.tabs.map(&:name).values_at(0, -1)
  ensure
    RedmineKitAws::Admin.instance_variable_get(:@tabs).delete('extra')
  end
end
