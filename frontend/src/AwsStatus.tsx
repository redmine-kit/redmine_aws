import {
  AttrGrid,
  AttrGridSkeleton,
  Button,
  CardBody,
  CardSection,
  EmptyState,
  Icon,
  ListRow,
  Notice,
  RequestErrorState,
  Skeleton,
  SkeletonRegion,
  StatusValue,
  type AttrItem,
} from '@redmine-kit/ui';
import { useApiErrorTexts, useKitMutation, useKitQuery, useT } from '@redmine-kit/plugin';
import { awsPaths, type AwsCheckJson, type AwsRow, type AwsSection, type AwsStatusJson } from './api';

// Administration › AWS › ステータス (/admin/aws/status: the manifest's layout: admin screen with menu_item aws, its tab
// label_aws_status at position 10). The app draws the card, its header (the admin menu item's caption, AWS) and the
// strip of the AWS tabs of every Redmine Kit AWS plugin; this draws the tab's content, as Redmine's page does
// (app/views/aws_status/index.html.erb): each section of values in its order (RedmineKit::Aws::Status#sections:
// バージョン, Parameter Store, and those the other AWS plugins register), then 接続テスト, whose テスト runs the checks of
// every installed plugin (POST check.json) and shows each result: its state, what it returned or the class of its
// error, and the time it took. The values come formatted by the server (Redmine's helpers); nothing here is a secret
// (the server sends names only).

/** The label column: Redmine's .tabular labels (175px), as the classic page's values line up. */
const LABEL_WIDTH = 175;

export function AwsStatus() {
  const t = useT();
  const query = useKitQuery<AwsStatusJson>(awsPaths.status);
  if (query.isError)
    return (
      <CardBody>
        <RequestErrorState error={query.error} onRetry={() => void query.refetch()} retrying={query.isFetching} />
      </CardBody>
    );
  return (
    <CardBody>
      {query.data ? (
        query.data.sections.map((section, index) => <ValuesSection key={section.name} section={section} line={index > 0} />)
      ) : (
        <StatusSkeleton label={t('label_loading')} />
      )}
      <ConnectionTest />
    </CardBody>
  );
}

/** A section of values: label and value pairs, or a list of names (Parameter Store's), or 「表示するデータがありません」. */
function ValuesSection({ section, line }: { section: AwsSection; line: boolean }) {
  const valued = section.rows.some((row) => row.value != null || row.note != null);
  return (
    <CardSection line={line} heading={section.label}>
      {section.rows.length === 0 ? (
        <EmptyState />
      ) : valued ? (
        <div className="px-gutter">
          <AttrGrid columns={1} labelWidth={LABEL_WIDTH} items={section.rows.map(valueItem)} />
        </div>
      ) : (
        section.rows.map((row, i) => <ListRow key={row.name} title={row.name} mono={row.code} size={36} divider={i < section.rows.length - 1} />)
      )}
    </CardSection>
  );
}

/** A row as an AttrGrid item: the value, with its note muted after it (the classic page's em.info). */
function valueItem(row: AwsRow): AttrItem {
  return { label: row.name, value: row.note ? <StatusValue detail={row.note}>{row.value ?? ''}</StatusValue> : (row.value ?? undefined) };
}

/**
 * The sections while the JSON loads: the section Redmine Kit AWS always has (バージョン: Redmine, Ruby, Rails and the
 * plugins), its heading and its first rows at the loaded rows' places; the plugins it lists and the other plugins'
 * sections come with the data.
 */
function StatusSkeleton({ label }: { label: string }) {
  const t = useT();
  return (
    <SkeletonRegion label={label}>
      <CardSection line={false} heading={<Skeleton width={72} height={12} />} label={t('label_aws_versions')}>
        <div className="px-gutter">
          <AttrGridSkeleton
            columns={1}
            labelWidth={LABEL_WIDTH}
            items={[{ label: 'Redmine', width: 40 }, { label: 'Ruby', width: 40 }, { label: 'Rails', width: 48 }, { label: t('plugin_name_redmine_kit_aws'), width: 40 }]}
          />
        </div>
      </CardSection>
    </SkeletonRegion>
  );
}

/** 接続テスト: テスト runs the checks (as the classic page's link, a POST), then their results. */
function ConnectionTest() {
  const t = useT();
  const check = useKitMutation<AwsCheckJson>(awsPaths.check, 'post');
  const errorTexts = useApiErrorTexts();
  const errors = errorTexts(check.error);
  const results = check.data?.results;
  return (
    <CardSection
      heading={t('label_aws_connection_check')}
      actions={
        <Button size={28} disabled={check.isPending} onClick={() => check.mutate({})}>
          {t('button_test')}
        </Button>
      }
    >
      {errors.length > 0 && <Notice tone="danger" role="alert" text={errors.join('\n')} wrap />}
      {results?.map((result, i) => (
        // a check as Administration › Information's checks are (ListRow): its name, then what it returned or the class of
        // its error under it, the time it took and its state at the right
        <ListRow
          key={result.name}
          title={result.name}
          sub={result.value ?? undefined}
          divider={i < results.length - 1}
          cols={[
            { content: result.note ?? '', kind: 'number', align: 'right' },
            {
              content: (
                <span className={result.ok ? 'flex text-accent' : 'flex text-warning'} role="img" aria-label={result.ok ? t('label_aws_ok') : t('label_aws_failed')}>
                  <Icon name={result.ok ? 'check' : 'warning'} size={16} />
                </span>
              ),
            },
          ]}
        />
      ))}
    </CardSection>
  );
}
