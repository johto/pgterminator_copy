CREATE OR REPLACE FUNCTION terminator.Waiting_PIDs(
OUT   ProtectedWaitingPIDs      integer[],
OUT UnprotectedOldestRunningPID integer
)
RETURNS RECORD
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN

SELECT array_agg(pid) INTO ProtectedWaitingPIDs
FROM pg_stat_activity_portable()
WHERE waiting IS TRUE
AND EXISTS (
    SELECT 1
    FROM terminator.Users
    WHERE terminator.Users.Protected IS TRUE
    AND  terminator.Users.Username        = pg_stat_activity_portable.usename
    AND (terminator.Users.ApplicationName = pg_stat_activity_portable.application_name OR terminator.Users.ApplicationName IS NULL)
);

SELECT pid INTO UnprotectedOldestRunningPID
FROM pg_stat_activity_portable()
WHERE xact_start < clock_timestamp()-'5 seconds'::interval
AND EXISTS (
    SELECT 1
    FROM terminator.Users
    WHERE terminator.Users.Protected IS FALSE
    AND  terminator.Users.Username        = pg_stat_activity_portable.usename
    AND (terminator.Users.ApplicationName = pg_stat_activity_portable.application_name OR terminator.Users.ApplicationName IS NULL)
)
ORDER BY xact_start
LIMIT 1;

IF ProtectedWaitingPIDs        IS NULL
OR UnprotectedOldestRunningPID IS NULL
THEN
    ProtectedWaitingPIDs        := NULL;
    UnprotectedOldestRunningPID := NULL;
END IF;

RETURN;
END;
$FUNC$;

ALTER FUNCTION terminator.Waiting_PIDs() OWNER TO sudo;

REVOKE ALL ON FUNCTION terminator.Waiting_PIDs() FROM PUBLIC;
GRANT  ALL ON FUNCTION terminator.Waiting_PIDs() TO pgterminator;
