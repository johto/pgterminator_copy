CREATE OR REPLACE FUNCTION terminator.Is_Protected(_Username text, _ApplicationName text)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_Protected boolean;
BEGIN

SELECT Protected
INTO  _Protected
FROM terminator.Users
WHERE Username      = _Username
AND ApplicationName = _ApplicationName;
IF FOUND THEN
    RETURN _Protected;
END IF;

SELECT Protected
INTO  _Protected
FROM terminator.Users
WHERE Username      = _Username
AND ApplicationName IS NULL;
IF FOUND THEN
    RETURN _Protected;
END IF;

RETURN NULL;

END;
$FUNC$;

ALTER FUNCTION terminator.Is_Protected(_Username text, _ApplicationName text) OWNER TO pgterminator;
