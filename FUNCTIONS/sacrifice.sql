CREATE OR REPLACE FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_LogID            integer;
_BlockingUsername text;
_BlockingQuery    text;
_WaitingUsername  text;
_WaitingQuery     text;
BEGIN

SELECT
    usename,
    query
INTO
    _WaitingUsername,
    _WaitingQuery
FROM pg_stat_activity_portable()
WHERE pid = _WaitingPID
AND waiting IS TRUE
AND usename IN (SELECT Username FROM terminator.Users WHERE Protected IS TRUE);
IF NOT FOUND THEN
    -- Probably not waiting anymore
    RETURN TRUE;
END IF;

SELECT
    usename,
    query
INTO
    _BlockingUsername,
    _BlockingQuery
FROM pg_stat_activity_portable()
WHERE pid = _BlockingPID
AND usename IN (SELECT Username FROM terminator.Users WHERE Protected IS FALSE);
IF NOT FOUND THEN
    -- Query probably finished already
    RETURN TRUE;
END IF;

INSERT INTO terminator.Log (
    BlockingUsername,
    BlockingPID,
    BlockingQuery,
    WaitingUsername,
    WaitingPID,
    WaitingQuery
)
VALUES (
    _BlockingUsername,
    _BlockingPID,
    _BlockingQuery,
    _WaitingUsername,
    _WaitingPID,
    _WaitingQuery
)
RETURNING LogID INTO STRICT _LogID;

RAISE NOTICE 'LogID % : Terminate user "%" PID % because user "%" PID % is waiting', _LogID, _BlockingUsername, _BlockingPID, _WaitingUsername, _WaitingPID;

PERFORM pg_terminate_backend(_BlockingPID);

RETURN _LogID;
END;
$FUNC$;

ALTER FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer) OWNER TO sudo;

REVOKE ALL ON FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer) FROM PUBLIC;
GRANT  ALL ON FUNCTION terminator.Sacrifice(_BlockingPID integer, _WaitingPID integer) TO pgterminator;
