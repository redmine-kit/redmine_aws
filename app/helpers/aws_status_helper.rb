# frozen_string_literal: true

# The rows of the Status tab (docs/admin.md#status), for Redmine's page and for
# the new UI's JSON alike.
module AwsStatusHelper
  # The connection test's results as rows of aws_admin/values: the check's
  # name, whether it passed, what it returned (or the class of its error) and
  # the time it took.
  def aws_check_rows(results)
    results.map do |result|
      { name: l(result.label), ok: result.ok, value: result.detail,
        note: "#{number_with_delimiter(result.milliseconds)} ms" }
    end
  end

  # A section's rows for aws_admin/values: a name that is code (a parameter's
  # name) in <code>.
  def aws_section_rows(rows)
    rows.map { |row| row[:code] ? row.except(:code).merge(name: tag.code(row[:name])) : row }
  end
end
