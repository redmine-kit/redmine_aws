# frozen_string_literal: true

# The "Status" tab (docs/admin.md#status).
class AwsStatusController < ApplicationController
  include RedmineAws::AdminTab

  def index
    @status = RedmineAws::Status.new
  end

  def check
    @status = RedmineAws::Status.new
    @results = RedmineAws::Admin.run_checks
    failed = @results.reject(&:ok).map(&:name)
    failed = failed.join(', ').presence || 'none'
    logger&.info "[redmine_aws] #{User.current.login} ran the connection check; failed: #{failed}"
    render :index
  end
end
