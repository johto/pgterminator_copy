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
WHERE usename IN (SELECT Username FROM terminator.Users WHERE Protected IS TRUE)
AND waiting IS TRUE;

SELECT pid INTO UnprotectedOldestRunningPID
FROM pg_stat_activity_portable()
WHERE usename IN (SELECT Username FROM terminator.Users WHERE Protected IS FALSE)
AND xact_start < clock_timestamp()-'5 seconds'::interval
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
