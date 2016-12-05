# pgterminator

Automatically terminate less important processes when more important processes are waiting.

## DESCRIPTION

Long running queries are not a problem,
as long as they don't force other important
parts of the system to wait for them to finish.

Another classic is a human user forgetting to COMMIT.

If you are a DBA and ever have had to manually
call pg_terminate_backend() to kill some
misbehaving backend process, then this tool
might be of interest.

To keep it simple, PgTerminator don't bother
to be nice and first try pg_cancel_query(),
but instead just calls pg_terminate_backend()
as soon as the problem conditions are met.

## ASSUMPTIONS

When there is a problem, it is usually lots of
important queries waiting for some single
blocking query.

It is not a problem if a lot of queries are
waiting for just a short period, like
a few seconds.

Some database users are more important than others,
like those that run the core of the system.
Let's call these the <code>Protected Users</code>.

Some database users are known to sometimes
cause problems, like human users and cronjobs,
and those are the ones we will consider to kill
under some conditions.
Let's call these the <code>Unprotected Users</code>.

All other database users that don't fall into
any of the two groups are ignored completely;
they won't be protected and they won't be killed.

If the limits are exceeded in
a) how many Protected Users that are waiting
and,
b) how long the one who's been waiting the longest has been waiting,
and,
c) at least one Unprotected User has an active query

We then want to start killing, and we want to kill
just one query at a time, since we don't know which
one is causing trouble.

We will assume the oldest query, i.e. the one
with the oldest xact_start is the trouble maker,
and we will begin by killing it, and if it doesn't
help, continue with the next one.

Only active queries running as Unprotected Users
will be considered.

If no Unprotected Users have any queries running,
but Protected Users are waiting, then there
is unfortunately nothing we can do as we won't
kill any other users than Unprotected Users.

## CONFIG

The default limits hard-coded in <code>pgterminator</code> are:

```
my $LimitMaxLongestWaitingSeconds = 5;
my $LimitMaxWaitingPIDs           = 3;
```

That is, start killing if at least 3 Protected Users are waiting,
and if the Protected User that has been waiting the longest
has been waiting for at least 5 seconds.

If you change them you have to restart <code>pgterminator</code>.

## SYNOPSIS

To protect the important user "foo":

```
INSERT INTO terminator.Users (Username, Protected) VALUES ('foo', TRUE);
```

To allow sacrificing the less important user "bar":
```
INSERT INTO terminator.Users (Username, Protected) VALUES ('bar', FALSE);
```

To run PgTerminator:
```
$ PGUSER=pgterminator PGDATABASE=foobar ./pgterminator
2016-12-06T19:09:46 PgTerminator is now running
```

## LOGGING

Before PgTerminator calls pg_terminate_backend(),
it will insert a row to terminator.Log:

```
LogID            serial      NOT NULL,
BlockingUsername text        NOT NULL,
BlockingPID      integer     NOT NULL,
BlockingQuery    text        NOT NULL,
WaitingUsername  text        NOT NULL,
WaitingPID       integer     NOT NULL,
WaitingQuery     text        NOT NULL,
Datestamp        timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (LogID)
```

## IMPLEMENTATION

Every second terminator.Waiting_PIDs() is called that
returns an array of ProtectedWaitingPIDs and
the UnprotectedOldestRunningPID.

For each waiting PID, we keep track of how
many seconds each PID has been waiting.

If a PID is not in the array returned from Waiting_PIDs()
that means the PID is not waiting any more
and is thus removed from the list.

When the limits are exceeded, the UnprotectedOldestRunningPID
is killed by executing terminator.Sacrifice(BlockingPID, WaitingPID),
which inserts a row to terminator.Log and then calls
pg_terminate_backend() on the BlockingPID.



