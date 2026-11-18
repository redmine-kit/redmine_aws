# frozen_string_literal: true

# The "AWS" item of the administration menu: opens the first tab of the
# installed Redmine Kit AWS plugins (RedmineKitAws::Admin).
class AwsAdminController < ApplicationController
  include RedmineKitAws::AdminTab

  def index
    tab = RedmineKitAws::Admin.tabs.first
    tab ? redirect_to(tab.url) : render_404
  end
end
