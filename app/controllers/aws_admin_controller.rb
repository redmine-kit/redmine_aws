# frozen_string_literal: true

# The "AWS" item of the administration menu: opens the first tab of the
# installed Redmine AWS plugins (RedmineAws::Admin).
class AwsAdminController < ApplicationController
  include RedmineAws::AdminTab

  def index
    tab = RedmineAws::Admin.tabs.first
    tab ? redirect_to(tab.url) : render_404
  end
end
