import { kitError, kitLoading, kitStory, userEvent, within, type Meta, type StoryObj } from '@redmine-kit/plugin/storybook';
import { AwsStatus } from './AwsStatus';
import { checks, checksEn, noParameters, status, statusEn } from './fixtures';

// the answers in the toolbar's language, as the server gives the headings and the checks' names in the user's
const english = () => document.documentElement.lang === 'en';
const statusAnswer = () => (english() ? statusEn : status);
const checksAnswer = () => (english() ? checksEn : checks);

// Administration › AWS › Status (the manifest's /admin/aws/status, a tab of the page AWS): the sections of values and the
// connection test, in the app's card with the page's title.
const meta = {
  title: 'Screens/AwsStatus',
  component: AwsStatus,
  ...kitStory({
    frame: 'card',
    bare: true,
    title: 'label_aws',
    responses: { 'GET /admin/aws/status.json': statusAnswer, 'POST /admin/aws/status/check.json': checksAnswer },
  }),
} satisfies Meta<typeof AwsStatus>;

export default meta;
type Story = StoryObj<typeof meta>;

const test = async ({ canvasElement }: { canvasElement: HTMLElement }) => {
  const canvas = within(canvasElement);
  await userEvent.click(await canvas.findByRole('button', { name: /テスト|Test/ }));
  await canvas.findByText('PostgreSQL 16.4');
};

/** The versions and the names Parameter Store set. */
export const Default: Story = {};

/** After Test: the database reached, S3 refused (the class of its error). */
export const Tested: Story = { play: test };

/** Test while the checks run: the button waits. */
export const Testing: Story = {
  ...kitStory({ responses: { 'GET /admin/aws/status.json': statusAnswer, 'POST /admin/aws/status/check.json': kitLoading } }),
  play: async ({ canvasElement }) => {
    await userEvent.click(await within(canvasElement).findByRole('button', { name: /テスト|Test/ }));
  },
};

/** The test was refused (a session that ended: Redmine's 422). */
export const TestFailed: Story = {
  ...kitStory({ responses: { 'GET /admin/aws/status.json': statusAnswer, 'POST /admin/aws/status/check.json': kitError(422, ['Invalid form authenticity token.']) } }),
  play: async ({ canvasElement }) => {
    await userEvent.click(await within(canvasElement).findByRole('button', { name: /テスト|Test/ }));
  },
};

/** Parameter Store set no variable: No data to display. */
export const NoParameters: Story = kitStory({ responses: { 'GET /admin/aws/status.json': () => ({ sections: [statusAnswer().sections[0], noParameters.sections[1]] }) } });

/** Without Redmine Kit AWS SSM: no Parameter Store section. */
export const WithoutParameterStore: Story = kitStory({ responses: { 'GET /admin/aws/status.json': () => ({ sections: [statusAnswer().sections[0]] }) } });

export const Loading: Story = kitStory({ state: 'loading' });

/** The values couldn't be read. */
export const Failed: Story = kitStory({ state: 'error' });

/** Redmine refused (not a system administrator): 403. */
export const Forbidden: Story = kitStory({ state: 'forbidden' });
