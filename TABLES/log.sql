CREATE TABLE terminator.Log (
LogID                   serial      NOT NULL,
BlockingUsername        text        NOT NULL,
BlockingApplicationName text        NULL,
BlockingPID             integer     NOT NULL,
BlockingQuery           text        NOT NULL,
WaitingUsername         text        NOT NULL,
WaitingApplicationName  text        NULL,
WaitingPID              integer     NOT NULL,
WaitingQuery            text        NOT NULL,
Datestamp               timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (LogID)
);

ALTER TABLE terminator.Log OWNER TO pgterminator;
