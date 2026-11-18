# frozen_string_literal: true

# The "AWS" item of the administration menu: opens the first tab of the
# installed Redmine Kit AWS plugins (RedmineKit::Aws::Admin).
class AwsAdminController < ApplicationController
  include RedmineKit::Aws::AdminTab

  def index
    tab = RedmineKit::Aws::Admin.tabs.first
    tab ? redirect_to(tab.url) : render_404
  end
end
