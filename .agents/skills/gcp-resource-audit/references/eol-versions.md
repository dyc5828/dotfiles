# Managed Runtime and Database EOL Reference

For each managed runtime or database version that surfaces in an audit, check whether it's past end-of-life (EOL) or end-of-standard-support. EOL versions are a flag worth surfacing because they often can't be upgraded in place and may cause migration delays.

EOL dates move. **Verify current status** via the relevant project's lifecycle page before quoting a status definitively.

## PostgreSQL

- **9.6 and earlier**: EOL well before 2024
- **10**: EOL November 2022
- **11**: EOL November 2023
- **12**: EOL November 2024
- **13**: EOL November 2025
- **14**: standard support through November 2026
- **15**: standard support through November 2027
- **16**: standard support through November 2028
- **17**: current

Upstream lifecycle policy: https://www.postgresql.org/support/versioning/

Cloud SQL publishes its own deprecation schedule, which usually trails upstream EOL by a few months: https://cloud.google.com/sql/docs/postgres/db-versions

## MySQL

- **5.6**: EOL February 2021
- **5.7**: EOL October 2023
- **8.0**: standard support through April 2026, extended support through April 2032
- **8.4 LTS**: current LTS

Upstream lifecycle: https://www.mysql.com/support/supportedplatforms/database.html

Cloud SQL MySQL versions: https://cloud.google.com/sql/docs/mysql/db-versions

## Python (Cloud Functions, App Engine, Cloud Run)

- **3.7**: EOL June 2023
- **3.8**: EOL October 2024
- **3.9**: EOL October 2025
- **3.10**: security only through October 2026
- **3.11**: security only through October 2027
- **3.12+**: current

Upstream lifecycle: https://devguide.python.org/versions/

GCP runtimes typically pin to specific minor versions and may end support before upstream EOL.

## Node.js (Cloud Functions, App Engine, Cloud Run)

- **14**: EOL April 2023
- **16**: EOL September 2023
- **18**: EOL April 2025
- **20 LTS**: maintenance through April 2026
- **22 LTS**: current

Upstream release schedule: https://github.com/nodejs/release#release-schedule

## Go (Cloud Functions, App Engine, Cloud Run)

Each Go release is supported until two newer major releases ship — so usually the two most recent versions are supported and anything older is out.

Release lifecycle: https://go.dev/doc/devel/release

## What to flag in an audit

For each managed resource you find with a version (Cloud SQL `databaseVersion`, Cloud Functions `runtime`, App Engine `runtime`, etc.):

1. Note the version explicitly
2. Compare against this reference or a fresh lookup
3. Flag any version that is:
   - **Past EOL** — no security updates; high migration risk
   - **Within 6 months of EOL** — should be planned
   - **Past Cloud SQL's deprecation date** even if upstream still supports it — GCP will force migration

### Wording suggestion

> Cloud SQL `api-production` runs Postgres 11, which reached EOL in November 2023. The instance cannot be upgraded in place from this version on Cloud SQL; migration requires a logical dump/restore or use of Cloud SQL's major version upgrade tooling.
