CREATE ROLE eng_seq     LOGIN NOCREATEDB NOCREATEROLE PASSWORD 'eng_seq';
CREATE ROLE eng_seq_ro  LOGIN NOCREATEDB NOCREATEROLE PASSWORD 'eng_seq_ro';
CREATE ROLE eng_seq_admin NOLOGIN NOCREATEDB NOCREATEROLE INHERIT;

GRANT eng_seq       TO rm7;
GRANT eng_seq_ro    TO rm7;
GRANT eng_seq_admin TO rm7;
GRANT eng_seq       TO eng_seq_admin;

CREATE SCHEMA eng_seq AUTHORIZATION eng_seq_admin;
GRANT USAGE ON SCHEMA eng_seq TO eng_seq_ro, eng_seq;
