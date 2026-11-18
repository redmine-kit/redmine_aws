# frozen_string_literal: true

module RedmineKit
  module Aws
    # For the controller of a tab of the AWS administration page: Redmine's
    # administration layout with the "AWS" menu item selected, for
    # administrators only (require_admin, as on Redmine's own administration
    # pages). The view starts with the tabs:
    #   <%= render partial: 'aws_admin/tabs', locals: { selected: 'jobs' } %>
    module AdminTab
      extend ActiveSupport::Concern

      included do
        layout 'admin'
        self.main_menu = false
        menu_item :aws

        before_action :require_admin
      end
    end
  end
end
