---
name: "sec-grafana-logs"
description: "Retrieve bounded Grafana logs for known eSign and SCS applications across global, restricted, DC1, and DC2"
version: 6
created: "2026-08-13"
updated: "2026-09-07"
---

# SEC Grafana Logs

## Parent procedure

1. Establish the Grafana environment (`global`, `restricted`, `dc1`, or `dc2`) and application instance. Reuse known context; ask only if missing. Use a narrow window around a supplied timestamp (convert epoch-millisecond refIds to UTC); otherwise default to the last hour.
2. Delegate once to `sec-log-worker`, passing the known namespace/application, identifiers, UTC range, symptom, and evidence needed. The same worker retrieves the error **and its preceding cause** before returning. Do not split routine trace correlation into another worker.
3. Keep diagnosis in the parent. If the worker is unavailable, use a read/bash-only worker with this skill. Do not query Grafana in the parent unless delegation itself is unavailable.

## Query known applications directly

Use a mapping supplied by the parent/user or the verified rows below. **Do not rediscover labels for known applications.** Grafana environment selects the cluster; application suffix selects the instance, not the cluster.

| Application | Grafana environment | Base selector | Parsed application filter | Evidence |
| --- | --- | --- | --- | --- |
| eSign | `global` | `{service_name="esi-engine"}` | Not yet verified; narrow by supplied ID/time | Successful S1 investigation, 2026-09-07 |
| eSign production pilot R1 | User-specified production cluster (`dc1` or `dc2`) | `{k8s_namespace_name="esi-prod"}` | `structured_appName="esi-engine-r1"` | User-provided working query, 2026-09-07; cluster not specified |

Do not extrapolate these mappings to Restricted, other instances, or SCS. The proposed Global `esi-test` / `esi-engine-s1` mapping returned zero records during verification; it is **not** a verified replacement for the successful service selector. Add durable rows only with actual matching records or a user-provided working query.

For Global eSign, use the known service and supplied identifier directly:

```logql
{service_name="esi-engine"} |= "<reference, order, token, or trace ID>"
```

For production pilot R1:

```logql
{k8s_namespace_name="esi-prod"}
  |= "<reference, order, token, or trace ID>"
  | json
  | structured_appName="esi-engine-r1"
  | line_format "{{.structured_message}}"
```

Raw-line ID filtering preserves searches on trace fields. Omit `line_format` when correlation IDs or stack traces are needed; inspect structured lines privately, not in parent output. Do not add a `tenant` filter unless needed and verified. Helper scopes `app` / `payload` select datasources, **not** Loki tenants.

### Only for unknown mappings

Use one concrete service or pod selector supplied by context. Known starting hints: eSign service `esi-engine`; SCS application-log service `common-services`; SCS payload service `sec-common-services`. Discover the namespace and application from a returned record, then reuse them. If the probe fails to establish a mapping, report the gap rather than cycling through guessed label names.

**Never use `{service_name=~".*"}`, `{k8s_pod_name=~".*"}`, or equivalent empty-compatible selectors.** Loki requires at least one matcher that cannot match an empty value. Do not replace `.*` with `.+` merely to scan every application.

## Execute and correlate

- Use `grafana-query.mjs` from this directory. Each query already performs session preflight: **do not run `check-session` first**. That command is for standalone authentication troubleshooting only.
- Run with an explicit timeout (`timeout 75s` for an ordinary query), default limit 20, and private output files. Convert UTC times with `date -d "$FROM" +%s%N` and `date -d "$TO" +%s%N`.

```bash
umask 077
RAW=$(mktemp)
DIAG=$(mktemp)
trap 'rm -f "$RAW" "$DIAG"' EXIT
timeout 75s ./grafana-query.mjs global app "$START_NS" "$END_NS" 20 "$QUERY" >"$RAW" 2>"$DIAG"
# Check exit status before parsing. Inspect bounded records and diagnostics only.
```

- If authentication fails, stop and ask for SSO at the exact reported host in Microsoft Edge. Do not retry until SSO is completed. Do not change the host cookie filter.
- **HTTP 400: stop the query sequence and report the failed query plus bounded server diagnostic.** It is not a label-discovery signal. Do not silently retry variants. Report other HTTP/timeouts too; no automatic retry loops.
- For successful results, inspect at most 20 records using bounded `jq`/`rg` output. Narrow the range if the limit is reached; a saturated result is not complete evidence.
- Normally use at most **three queries**: identifier, discovered trace, then exact-pod context around the earliest failure if its cause is missing. Prefer narrower time ranges to higher limits. If still unresolved, return the gap rather than unbounded discovery.
- Follow the earliest causal event: a missing-token error may follow earlier token expiry/deletion. Retrieve that preceding exception in the same worker. Exact-text filters can omit multiline causes; use the verified pod and a few seconds around the failure when needed.
- Search payload logs only when application logs are insufficient. Return only diagnostic fields, never PDF bodies, personal data, or credentials.
- Sort evidence by Loki's outer nanosecond timestamp. Delete raw temporary files before returning.

## Evidence bundle

Return a concise bundle:
- Environment, application/namespace, exact UTC range, and exact queries.
- At most 20 timestamp-sorted sanitized messages, with logger/pod/correlation IDs where useful.
- The earliest relevant exception and preceding events, or a clear evidence gap.
- **Total retrieval elapsed time, helper timings, query count, every failed query/status/diagnostic, and zero-result searches.** Never present failed requests as successful searches or hide them from the parent.

## Count mode (only for explicit aggregation requests)

```bash
./grafana-query.mjs <environment> <app|payload> <start> <end> 20 \
  --window-hours 24 --count-regex '<regex with one numeric capture>' <LogQL>
```

At most 31 windows; require `complete: true`. Narrow saturated windows before using statistics. Use a timeout appropriate to the explicitly bounded aggregation. The three-query diagnostic budget does not apply to requested aggregation windows.

## Safety and verification

- Never print or persist Grafana cookies, OpenShift tokens, raw payloads, credentials, or personal data. Never run `oc` without explicit user authorization.
- Retain exact-host cookie isolation, private temporary files, and cleanup. Use `EDGE_BINARY`, `EDGE_PROFILE_ROOT`, or `EDGE_PROFILE_NAME` only for nonstandard Edge setups.
- Validate helper changes with `node grafana-query.mjs self-test` and `node --check grafana-query.mjs`. `app`/`payload` and legacy `sec-app`/`sec-payload` aliases remain supported.
- For a live check, use one known-app query without separate preflight. Require HTTP 200/Loki `success`, bounded sanitized output, elapsed timing, and deleted raw files.
