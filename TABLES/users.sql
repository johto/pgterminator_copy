CREATE TABLE terminator.Users (
Username  text    NOT NULL,
Protected boolean NOT NULL,
PRIMARY KEY (Username)
);

ALTER TABLE terminator.Users OWNER TO pgterminator;
