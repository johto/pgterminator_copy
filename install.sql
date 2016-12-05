ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
CREATE USER sudo WITH SUPERUSER;
COMMIT;
BEGIN;
CREATE USER pgterminator;
COMMIT;
BEGIN;
DROP SCHEMA terminator CASCADE;
COMMIT;
BEGIN;
CREATE SCHEMA terminator;
\ir TABLES/users.sql
\ir TABLES/log.sql
\ir FUNCTIONS/pg_stat_activity_portable.sql
\ir FUNCTIONS/waiting_pids.sql
\ir FUNCTIONS/sacrifice.sql
GRANT USAGE ON SCHEMA terminator TO pgterminator;

COMMIT;
