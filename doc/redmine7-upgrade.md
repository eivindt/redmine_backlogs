# Upgrading redmine_backlogs from Redmine 4.1 to Redmine 7.0 (PostgreSQL)

This runbook covers moving an existing Redmine 4.1.0 installation with this
plugin (migrations 011 to 049 applied) to Redmine 7.0.1 with the `redmine7`
branch of the plugin. It was rehearsed on 2026-09-16 against an export of the
`gnss-obu-software-development` project (3688 issues, 76 sprints, 14 releases)
loaded into a fresh 4.1 schema on PostgreSQL 17, then upgraded in place.

## What the redmine7 branch changes

The branch is based on `maedadev/master` (maintained fork, Redmine 5+, Rails 7.1)
plus the commits listed by `git log maedadev/master..redmine7`:

- routes rewritten for Rails 8.1 (`resource :only => :none` and hash arguments
  to `match` are rejected there)
- migration 050 only runs on MySQL (`mediumtext` does not exist in PostgreSQL)
- two PostgreSQL fixes that broke moving stories between sprints and creating
  tasks on the taskboard (nil bind parameter compared with `IS NULL`; table
  qualified column in an UPDATE SET clause)
- the plugin page layout rebuilt on Redmine 7's `layouts/base.html.erb`
- the release multiview burnchart re-enabled (as in the local fork since 2020)
- task create/update exceptions reported through the normal error box
- context menu permission, crossing estimate guard (from the local fork)
- `File.exist?` for Ruby 3.2, two missing English labels
- `etc/export_backlogs_project.psql` and `etc/import_backlogs_export.sh` for
  building a test database from one project

## Prerequisites

- Ruby 3.2.3 with `bundler`, plus `build-essential libpq-dev libyaml-dev`
  for the native gems (`pg`, `nokogiri`, `json`).
- PostgreSQL 17. The database must already be restored on the new server.
- Redmine 7.0.1 source tree with `config/database.yml`,
  `config/configuration.yml` and `files/` carried over from 4.1.
- A `Gemfile.local` containing `gem 'puma'` if the app server is puma
  (Redmine keeps puma in the development group).
- Redmine 7 compatible versions of every other plugin that stays installed.
  Two of them add columns to tables this plugin also uses (`versions.in_timesheet`,
  `versions.is_order`, `time_entries.order_id`, `time_entries.order_activity_id`);
  that is harmless for backlogs.
- The plugin's own gems are pulled in through its `Gemfile`: sidekiq, erubis,
  holidays, icalendar, open-uri-cached, prawn, json, matrix.

## Before starting

Take a dump and record the plugin's migration state and row counts:

```sql
select count(*) from schema_migrations where version like '%-redmine_backlogs';  -- 29 on 4.1
select count(*) from issues;
select count(*) from rb_issue_history;
select count(*) from rb_sprint_burndown;
select count(*) from releases;
select count(*) from rb_release_burnchart_day_caches;
select count(*) from versions where sprint_start_date is not null;
```

The plugin settings live in one row: `select value from settings where
name = 'plugin_redmine_backlogs'`. They are carried over unchanged; the new
code reads the same keys.

## Procedure

Run everything as the Redmine user in the Redmine 7.0.1 directory with
`RAILS_ENV=production`.

1. Place the plugins under `plugins/`, with `plugins/redmine_backlogs` checked
   out at the `redmine7` branch.
2. Install gems:

   ```
   bundle config set --local without 'development test'
   bundle install
   ```

3. Migrate the core database from 4.1 to 7.0.1. All old core migrations are
   still shipped, so this is a direct jump. The plugin may be present while this
   runs; the rehearsal did it that way.

   ```
   bundle exec rake db:migrate
   ```

4. Migrate the plugins. For backlogs this applies 050 (no-op on PostgreSQL)
   and 051 (`issues.position` gets `NOT NULL DEFAULT 0`). No data is rewritten.

   ```
   bundle exec rake redmine:plugins:migrate
   ```

5. Clear caches and start the application server.

   ```
   bundle exec rake tmp:cache:clear
   ```

   Plugin assets need no separate step. Redmine 7 serves them through
   Propshaft and compiles them at startup when they change.

## Verification

- `select count(*) from schema_migrations where version like '%-redmine_backlogs'`
  now returns 31.
- The row counts recorded before are unchanged.
- Log in and open, for a project using the plugin: master backlog, taskboard of
  the current sprint, releases list, one release with a burnup chart, a sprint
  burndown, Scrum statistics, and the issue list with the `Story points` and
  `Release` columns. Drag one story between two sprints and back.
- `log/production.log` shows no `Completed 500` lines and no `DEPRECATION
  WARNING` lines mentioning `redmine_backlogs`.

## Rollback

Redmine core migrations are not meant to be reversed across major versions.
Rollback is: stop the application, restore the pre-upgrade dump, and start the
old 4.1 code again.

## Rehearsing on a copy of one project

The rehearsal that produced this runbook used two scripts from `etc/`:

1. On the production database, as a database user with read access, export one
   project tree. The script is read-only, needs psql 12 or newer and writes CSV
   files without password hashes or e-mail addresses:

   ```
   mkdir backlogs_export && cd backlogs_export
   psql -h HOST -U USER -d DBNAME -v ident=PROJECT_IDENTIFIER \
        -f /path/to/etc/export_backlogs_project.psql
   ```

2. Create an empty PostgreSQL database and migrate it with Redmine 4.1 *without*
   the plugin directory present (the plugin touches the Issue model at boot and
   fails on an empty schema), then add the plugin and run
   `redmine:plugins:migrate`.
3. Load the export. Columns unknown to the target schema are dropped and
   sequences are reset:

   ```
   PGPASSWORD=... etc/import_backlogs_export.sh backlogs_export -h HOST -p PORT -U USER -d DBNAME
   ```

4. Give yourself a login (`rails runner`: find or create an admin user and set a
   password), then follow the procedure above with Redmine 7.

## Known gaps

- Printable cards (`/rb/stories/...pdf`) fail because the card label file is
  fetched by an installer task that was not run. The feature is not in use.
- The iCal sprint calendar was not exercised. The feature is not in use.
- `GET /rb/tasks/:story_id` is routed to an action the controller no longer
  has. The page JavaScript never calls it.
- `app/workers/backlogs_after_save.rb` defines a Sidekiq worker that nothing
  enqueues; the sidekiq gem is still installed because the plugin `Gemfile`
  lists it.
- With the standard Redmine header switched on for backlogs pages
  (`show_redmine_std_header`), the breadcrumb wraps under the project title.
  Production runs with the compact header, where this does not apply.
- The plugin still ships its own jQuery 1.7.2 and jQuery UI 1.8.21, isolated as
  `RB.$` via `noConflict`, next to Redmine's jQuery 3.7.1. This is upstream's
  approach and produced no JavaScript errors in the rehearsal.
