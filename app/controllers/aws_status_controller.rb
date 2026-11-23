# frozen_string_literal: true

# The "Status" tab (docs/admin.md#status): Redmine's page, and the same values
# as JSON for the new UI's tab (AwsStatus of frontend/).
class AwsStatusController < ApplicationController
  include RedmineKit::Aws::AdminTab

  helper :aws_status

  def index
    @status = RedmineKit::Aws::Status.new
    respond_to do |format|
      format.html
      format.json { render json: { sections: @status.sections(view_context) } }
    end
  end

  def check
    @status = RedmineKit::Aws::Status.new
    @results = RedmineKit::Aws::Admin.run_checks
    log_check
    respond_to do |format|
      format.html { render :index }
      format.json { render json: { results: view_context.aws_check_rows(@results) } }
    end
  end

  private

  # Who ran the connection test, and which checks failed.
  def log_check
    failed = @results.reject(&:ok).map(&:name).join(', ').presence || 'none'
    logger&.info "[redmine_kit_aws] #{User.current.login} ran the connection check; failed: #{failed}"
  end
end
