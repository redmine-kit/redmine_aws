# frozen_string_literal: true

# The "Status" tab (docs/admin.md#status).
class AwsStatusController < ApplicationController
  include RedmineKit::Aws::AdminTab

  def index
    @status = RedmineKit::Aws::Status.new
  end

  def check
    @status = RedmineKit::Aws::Status.new
    @results = RedmineKit::Aws::Admin.run_checks
    failed = @results.reject(&:ok).map(&:name)
    failed = failed.join(', ').presence || 'none'
    logger&.info "[redmine_kit_aws] #{User.current.login} ran the connection check; failed: #{failed}"
    render :index
  end
end
