import { screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { KitTestRequest } from '@redmine-kit/plugin/testing';
import { ApiError } from '@redmine-kit/plugin';
import { describe, expect, it } from 'vitest';
import { AwsStatus } from './AwsStatus';
import { checks, noParameters, status } from './fixtures';
import { renderKit } from './test/render';

// The Status tab on the plugin's JSON as AwsStatusController answers it.
const STATUS = 'GET /admin/aws/status.json';
const CHECK = 'POST /admin/aws/status/check.json';

describe('AwsStatus', () => {
  it('shows each section of values in its order, with its heading and rows', async () => {
    renderKit(<AwsStatus />, { responses: { [STATUS]: status } });
    await screen.findByText('7.0.3.stable');
    const versions = screen.getByRole('region', { name: 'バージョン' });
    expect(within(versions).getByText('Redmine')).toBeInTheDocument();
    expect(within(versions).getByText('7.0.3.stable')).toBeInTheDocument();
    expect(within(versions).getByText('Redmine Kit AWS SSM')).toBeInTheDocument();
    const parameters = screen.getByRole('region', { name: 'Parameter Store' });
    expect(within(parameters).getByText('SECRET_KEY_BASE')).toBeInTheDocument();
    expect(within(parameters).getByText('DATABASE_URL')).toBeInTheDocument();
    const headings = screen.getAllByRole('heading').map((h) => h.textContent);
    expect(headings).toEqual(['バージョン', 'Parameter Store', '接続テスト']);
  });

  it('says 表示するデータがありません for a section without rows, and leaves out a section the server leaves out', async () => {
    renderKit(<AwsStatus />, { responses: { [STATUS]: noParameters } });
    const parameters = await screen.findByRole('region', { name: 'Parameter Store' });
    expect(within(parameters).getByText('表示するデータがありません')).toBeInTheDocument();
  });

  it('runs the connection test with テスト (a POST) and shows each result, its state, what it returned and its time', async () => {
    const user = userEvent.setup();
    const requests: KitTestRequest[] = [];
    renderKit(<AwsStatus />, { requests, responses: { [STATUS]: status, [CHECK]: checks } });
    const test = await screen.findByRole('region', { name: '接続テスト' });
    expect(within(test).queryByText('PostgreSQL 16.4')).toBeNull();
    await user.click(within(test).getByRole('button', { name: 'テスト' }));
    expect(await within(test).findByText('PostgreSQL 16.4')).toBeInTheDocument();
    expect(requests.filter((r) => r.method !== 'get')).toEqual([{ method: 'post', path: '/admin/aws/status/check.json', body: {} }]);
    expect(within(test).getByText('データベース')).toBeInTheDocument();
    expect(within(test).getByText('12 ms')).toBeInTheDocument();
    expect(within(test).getByText('Aws::S3::Errors::Forbidden')).toBeInTheDocument();
    expect(within(test).getByText('1,204 ms')).toBeInTheDocument();
    // the state in words, not by the icon alone
    expect(within(test).getByRole('img', { name: 'OK' })).toBeInTheDocument();
    expect(within(test).getByRole('img', { name: '失敗' })).toBeInTheDocument();
  });

  it('shows the error state when the values cannot be read', async () => {
    renderKit(<AwsStatus />, { responses: { [STATUS]: new ApiError(500, []) } });
    expect(await screen.findByRole('button', { name: /再読み込み|再試行/ })).toBeInTheDocument();
  });

  it('is a skeleton while the values load, with the connection test already there', () => {
    renderKit(<AwsStatus />, { responses: { [STATUS]: new Promise(() => {}) } });
    expect(screen.getByRole('status', { name: 'ロード中...' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'テスト' })).toBeInTheDocument();
  });
});
