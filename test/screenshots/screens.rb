# frozen_string_literal: true

require_relative '../test_helper'
require File.join(Redmine::Plugin.find(:redmine_kit_aws).directory, 'test/support/redmine_kit/aws/screenshot_case')

module RedmineKit
  module Aws
    # The screens of docs/admin.md.
    class ScreenshotsTest < ScreenshotCase
      self.docs = File.expand_path('../../docs', __dir__)

      def test_screens
        each_language do |language|
          visit '/admin/aws/status'
          shoot 'admin-menu', language, selector: '#sidebar ul'

          click_link I18n.t(:button_test, locale: language)
          assert_selector 'table.list.checks'
          shoot 'status', language
        end
      end
    end
  end
end
