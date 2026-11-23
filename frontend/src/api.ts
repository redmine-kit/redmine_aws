// The plugin's JSON (AwsStatusController): the paths the tab reads and writes, and the shapes of its answers.

/** The Status tab's JSON paths (config/routes.rb). */
export const awsPaths = {
  /** GET: the sections of values (index.json) */
  status: '/admin/aws/status.json',
  /** POST: the connection test (check.json) */
  check: '/admin/aws/status/check.json',
};

/**
 * A row of values (the rows of aws_admin/values): its name, the value and a note under it, all formatted by the server
 * with Redmine's helpers; `code`: the name is code (a parameter's name); `ok`: a check's result.
 */
export interface AwsRow {
  name: string;
  value?: string | null;
  note?: string | null;
  code?: boolean;
  ok?: boolean;
}

/** A section of the Status tab (RedmineKit::Aws::Status#sections): its heading in the user's language and its rows. */
export interface AwsSection {
  name: string;
  label: string;
  rows: AwsRow[];
}

/** GET /admin/aws/status.json */
export interface AwsStatusJson {
  sections: AwsSection[];
}

/** POST /admin/aws/status/check.json: one row per check (AwsStatusHelper#aws_check_rows). */
export interface AwsCheckJson {
  results: (AwsRow & { ok: boolean })[];
}
