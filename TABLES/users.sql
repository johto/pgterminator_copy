CREATE TABLE terminator.Users (
UserID          serial  NOT NULL,
Username        text    NOT NULL,
ApplicationName text    NULL,
Protected       boolean NOT NULL,
PRIMARY KEY (UserID),
UNIQUE(Username,ApplicationName)
);

CREATE UNIQUE INDEX ON terminator.Users (Username) WHERE ApplicationName IS NULL;

ALTER TABLE terminator.Users OWNER TO pgterminator;
