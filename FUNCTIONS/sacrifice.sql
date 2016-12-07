CREATE OR REPLACE FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_LogID                   integer;
_BlockingUsername        text;
_BlockingApplicationName text;
_BlockingQuery           text;
_WaitingUsername         text;
_WaitingApplicationName  text;
_WaitingQuery            text;
BEGIN

SELECT
    usename,
    application_name,
    query
INTO
    _WaitingUsername,
    _WaitingApplicationName,
    _WaitingQuery
FROM pg_stat_activity_portable()
WHERE pid = _WaitingPID
AND waiting IS TRUE
AND EXISTS (
    SELECT 1
    FROM terminator.Users
    WHERE terminator.Users.Protected IS TRUE
    AND  terminator.Users.Username        = pg_stat_activity_portable.usename
    AND (terminator.Users.ApplicationName = pg_stat_activity_portable.application_name OR terminator.Users.ApplicationName IS NULL)
);
IF NOT FOUND THEN
    -- Probably not waiting anymore
    RETURN TRUE;
END IF;

SELECT
    usename,
    application_name,
    query
INTO
    _BlockingUsername,
    _BlockingApplicationName,
    _BlockingQuery
FROM pg_stat_activity_portable()
WHERE pid = _BlockingPID
AND EXISTS (
    SELECT 1
    FROM terminator.Users
    WHERE terminator.Users.Protected IS FALSE
    AND  terminator.Users.Username        = pg_stat_activity_portable.usename
    AND (terminator.Users.ApplicationName = pg_stat_activity_portable.application_name OR terminator.Users.ApplicationName IS NULL)
);
IF NOT FOUND THEN
    -- Query probably finished already
    RETURN TRUE;
END IF;

INSERT INTO terminator.Log (
    BlockingUsername,
    BlockingApplicationName,
    BlockingPID,
    BlockingQuery,
    WaitingUsername,
    WaitingApplicationName,
    WaitingPID,
    WaitingQuery
)
VALUES (
    _BlockingUsername,
    _BlockingApplicationName,
    _BlockingPID,
    _BlockingQuery,
    _WaitingUsername,
    _WaitingApplicationName,
    _WaitingPID,
    _WaitingQuery
)
RETURNING LogID INTO STRICT _LogID;

RAISE NOTICE 'LogID % : Terminate user "%" application_name "%" PID % because user "%" application_name "%" PID % is waiting', _LogID, _BlockingUsername, _BlockingApplicationName, _BlockingPID, _WaitingUsername, _WaitingApplicationName, _WaitingPID;

PERFORM pg_terminate_backend(_BlockingPID);

RETURN _LogID;
END;
$FUNC$;

ALTER FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer) OWNER TO sudo;

REVOKE ALL ON FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer) FROM PUBLIC;
GRANT  ALL ON FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer) TO pgterminator;
