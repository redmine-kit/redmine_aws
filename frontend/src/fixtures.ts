import type { AwsCheckJson, AwsStatusJson } from './api';

// The stories' and tests' data: the plugin's JSON as AwsStatusController answers it.

// GET /admin/aws/status.json: Redmine Kit AWS with Redmine Kit AWS SSM (Parameter Store)
export const status: AwsStatusJson = {
  sections: [
    {
      name: 'versions',
      label: 'バージョン',
      rows: [
        { name: 'Redmine', value: '7.0.3.stable' },
        { name: 'Ruby', value: '4.0.1' },
        { name: 'Rails', value: '8.1.2' },
        { name: 'Redmine Kit AWS', value: '0.1.0' },
        { name: 'Redmine Kit AWS SSM', value: '0.1.0' },
      ],
    },
    { name: 'loaded_settings', label: 'Parameter Store', rows: [{ name: 'SECRET_KEY_BASE', code: true }, { name: 'DATABASE_URL', code: true }] },
  ],
};

// the same, English (the server gives the headings in the user's language)
export const statusEn: AwsStatusJson = {
  sections: status.sections.map((section) => (section.name === 'versions' ? { ...section, label: 'Versions' } : section)),
};

// Parameter Store read no variable (Redmine Kit AWS SSM installed, every variable already set)
export const noParameters: AwsStatusJson = {
  sections: [status.sections[0], { name: 'loaded_settings', label: 'Parameter Store', rows: [] }],
};

// POST /admin/aws/status/check.json: the database reached, S3 refused
export const checks: AwsCheckJson = {
  results: [
    { name: 'データベース', ok: true, value: 'PostgreSQL 16.4', note: '12 ms' },
    { name: 'S3', ok: false, value: 'Aws::S3::Errors::Forbidden', note: '1,204 ms' },
  ],
};

// the same, English
export const checksEn: AwsCheckJson = {
  results: checks.results.map((row) => (row.name === 'データベース' ? { ...row, name: 'Database' } : row)),
};
