# frozen_string_literal: true

# The "Status" tab (docs/admin.md#status).
class AwsStatusController < ApplicationController
  include RedmineKitAws::AdminTab

  def index
    @status = RedmineKitAws::Status.new
  end

  def check
    @status = RedmineKitAws::Status.new
    @results = RedmineKitAws::Admin.run_checks
    failed = @results.reject(&:ok).map(&:name)
    failed = failed.join(', ').presence || 'none'
    logger&.info "[redmine_kit_aws] #{User.current.login} ran the connection check; failed: #{failed}"
    render :index
  end
end
