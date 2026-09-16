#!/usr/bin/env bash
# Load the CSV files produced by export_backlogs_project.psql into a freshly
# migrated Redmine database (core + redmine_backlogs migrations applied).
#
# Columns present in the CSV but unknown to the target table (added by other
# plugins in the source installation) are dropped. Target tables are truncated
# before loading. Sequences are reset afterwards.
#
# Usage:
#   PGPASSWORD=... ./import_backlogs_export.sh EXPORT_DIR -h HOST -p PORT -U USER -d DBNAME
set -euo pipefail

export_dir=$1; shift
psql_args=("$@")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

psql_q() { psql "${psql_args[@]}" -v ON_ERROR_STOP=1 -X -q -At "$@"; }

for csv in "$export_dir"/exp_*.csv; do
  table=$(basename "$csv" .csv); table=${table#exp_}
  case "$table" in schema_migrations|server_version) continue;; esac

  target_cols=$(psql_q -c "select string_agg(column_name, ',' order by ordinal_position) from information_schema.columns where table_schema='public' and table_name='$table'")
  if [ -z "$target_cols" ]; then
    echo "SKIP  $table (no such table in target)"; continue
  fi

  cols=$(python3 - "$csv" "$work/$table.csv" "$target_cols" <<'PY'
import csv, sys
src, dst, target = sys.argv[1], sys.argv[2], sys.argv[3].split(',')
csv.field_size_limit(1 << 30)
with open(src, newline='') as f, open(dst, 'w', newline='') as out:
    r = csv.reader(f)
    header = next(r)
    keep = [i for i, c in enumerate(header) if c in target]
    w = csv.writer(out, lineterminator='\n')
    for row in r:
        w.writerow([row[i] for i in keep])
    dropped = [c for c in header if c not in target]
    if dropped:
        print("dropped columns from %s: %s" % (src.split('/')[-1], ','.join(dropped)), file=sys.stderr)
    print(','.join(header[i] for i in keep))
PY
)
  # psql's CSV output writes both NULL and '' as an empty field; keep NOT NULL text columns as ''
  notnull_text=$(psql_q -c "select string_agg(column_name, ',') from information_schema.columns where table_schema='public' and table_name='$table' and is_nullable='NO' and data_type in ('character varying','text','character') and column_name in (select unnest(string_to_array('$cols', ',')))")
  force=""; [ -n "$notnull_text" ] && force=", force_not_null ($notnull_text)"
  psql_q -c "truncate table $table" -c "\\copy $table($cols) from '$work/$table.csv' with (format csv$force)"
  n=$(psql_q -c "select count(*) from $table")
  printf "%-36s %6s rows\n" "$table" "$n"
done

# Reset sequences for every table that has an id column
psql_q -c "with t as materialized (select table_name from information_schema.columns where table_schema='public' and column_name='id') select 'select setval(''' || pg_get_serial_sequence(table_name, 'id') || ''', coalesce((select max(id) from ' || table_name || '), 0) + 1, false);' from t where pg_get_serial_sequence(table_name, 'id') is not null" \
  | psql_q -f - >/dev/null
echo "sequences reset"
