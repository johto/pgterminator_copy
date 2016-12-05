CREATE TABLE terminator.Log (
LogID            serial      NOT NULL,
BlockingUsername text        NOT NULL,
BlockingPID      integer     NOT NULL,
BlockingQuery    text        NOT NULL,
WaitingUsername  text        NOT NULL,
WaitingPID       integer     NOT NULL,
WaitingQuery     text        NOT NULL,
Datestamp        timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (LogID)
);

ALTER TABLE terminator.Log OWNER TO pgterminator;
