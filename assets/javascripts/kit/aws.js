// Redmine Kit AWS: the plugin's module for the new UI, built from frontend/src by `npm run build` (frontend/vite.config.js).
// Edit the source, not this file. React, @redmine-kit/ui and @redmine-kit/plugin come from the app (the shell's import map).
import { AttrGrid, AttrGridSkeleton, Button, CardBody, CardSection, EmptyState, Icon, ListRow, Notice, RequestErrorState, Skeleton, SkeletonRegion } from "@redmine-kit/ui";
import { useApiErrorTexts, useKitMutation, useKitQuery, useT } from "@redmine-kit/plugin";
import { jsx, jsxs } from "react/jsx-runtime";
// src/api.ts
/** The Status tab's JSON paths (config/routes.rb). */
var awsPaths = {
	/** GET: the sections of values (index.json) */
	status: "/admin/aws/status.json",
	/** POST: the connection test (check.json) */
	check: "/admin/aws/status/check.json"
};
// src/AwsStatus.tsx
/** The label column: Redmine's .tabular labels (175px), as the classic page's values line up. */
var LABEL_WIDTH = 175;
function AwsStatus() {
	const t = useT();
	const query = useKitQuery(awsPaths.status);
	if (query.isError) return /* @__PURE__ */ jsx(CardBody, { children: /* @__PURE__ */ jsx(RequestErrorState, {
		error: query.error,
		onRetry: () => void query.refetch(),
		retrying: query.isFetching
	}) });
	return /* @__PURE__ */ jsxs(CardBody, { children: [query.data ? query.data.sections.map((section, index) => /* @__PURE__ */ jsx(ValuesSection, {
		section,
		line: index > 0
	}, section.name)) : /* @__PURE__ */ jsx(StatusSkeleton, { label: t("label_loading") }), /* @__PURE__ */ jsx(ConnectionTest, {})] });
}
/** A section of values: label and value pairs, or a list of names (Parameter Store's), or 「表示するデータがありません」. */
function ValuesSection({ section, line }) {
	const valued = section.rows.some((row) => row.value != null || row.note != null);
	return /* @__PURE__ */ jsx(CardSection, {
		line,
		heading: section.label,
		children: section.rows.length === 0 ? /* @__PURE__ */ jsx(EmptyState, {}) : valued ? /* @__PURE__ */ jsx("div", {
			className: "px-gutter",
			children: /* @__PURE__ */ jsx(AttrGrid, {
				columns: 1,
				labelWidth: LABEL_WIDTH,
				items: section.rows.map(valueItem)
			})
		}) : section.rows.map((row, i) => /* @__PURE__ */ jsx(ListRow, {
			title: row.name,
			mono: row.code,
			size: 36,
			divider: i < section.rows.length - 1
		}, row.name))
	});
}
/**
* A row as an AttrGrid item: the value with its note muted under it, as Redmine's em.info under a value (REDMINE_ROLE, the
* variable a value comes from); a long value (an image URI with its digest) wraps anywhere rather than being cut.
*/
function valueItem(row) {
	return {
		label: row.name,
		value: /* @__PURE__ */ jsxs("span", {
			className: "flex min-w-0 flex-col whitespace-normal wrap-anywhere",
			children: [/* @__PURE__ */ jsx("span", { children: row.value ?? "" }), row.note && /* @__PURE__ */ jsx("span", {
				className: "text-meta text-text-muted",
				children: row.note
			})]
		})
	};
}
/**
* The sections while the JSON loads: the section Redmine Kit AWS always has (バージョン: Redmine, Ruby, Rails and the
* plugins), its heading and its first rows at the loaded rows' places; the plugins it lists and the other plugins'
* sections come with the data.
*/
function StatusSkeleton({ label }) {
	const t = useT();
	return /* @__PURE__ */ jsx(SkeletonRegion, {
		label,
		children: /* @__PURE__ */ jsx(CardSection, {
			line: false,
			heading: /* @__PURE__ */ jsx(Skeleton, {
				width: 72,
				height: 12
			}),
			label: t("label_aws_versions"),
			children: /* @__PURE__ */ jsx("div", {
				className: "px-gutter",
				children: /* @__PURE__ */ jsx(AttrGridSkeleton, {
					columns: 1,
					labelWidth: LABEL_WIDTH,
					items: [
						{
							label: "Redmine",
							width: 40
						},
						{
							label: "Ruby",
							width: 40
						},
						{
							label: "Rails",
							width: 48
						},
						{
							label: t("plugin_name_redmine_kit_aws"),
							width: 40
						}
					]
				})
			})
		})
	});
}
/** 接続テスト: テスト runs the checks (as the classic page's link, a POST), then their results. */
function ConnectionTest() {
	const t = useT();
	const check = useKitMutation(awsPaths.check, "post");
	const errors = useApiErrorTexts()(check.error);
	const results = check.data?.results;
	return /* @__PURE__ */ jsxs(CardSection, {
		heading: t("label_aws_connection_check"),
		actions: /* @__PURE__ */ jsx(Button, {
			size: 28,
			disabled: check.isPending,
			onClick: () => check.mutate({}),
			children: t("button_test")
		}),
		children: [errors.length > 0 && /* @__PURE__ */ jsx(Notice, {
			tone: "danger",
			role: "alert",
			text: errors.join("\n"),
			wrap: true
		}), results?.map((result, i) => /* @__PURE__ */ jsx(ListRow, {
			title: result.name,
			sub: result.value ?? void 0,
			divider: i < results.length - 1,
			cols: [{
				content: result.note ?? "",
				kind: "number",
				align: "right"
			}, { content: /* @__PURE__ */ jsx("span", {
				className: result.ok ? "flex text-accent" : "flex text-warning",
				role: "img",
				"aria-label": result.ok ? t("label_aws_ok") : t("label_aws_failed"),
				children: /* @__PURE__ */ jsx(Icon, {
					name: result.ok ? "check" : "warning",
					size: 16
				})
			}) }]
		}, result.name))]
	});
}
export { AwsStatus };
