-- script to load the data from the csv file les_arbres_upload_v02.csv
-- file is UTF8, proper comma delimiter and line returns, proper headers

-- create database
CREATE DATABASE treesdb_v01
    WITH
    OWNER = alexis
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- create trees table

CREATE TABLE trees (
    idbase INTEGER,
    location_type VARCHAR,
    domain VARCHAR,
    arrondissement VARCHAR,
    suppl_address VARCHAR,
    number VARCHAR,
    address VARCHAR,
    id_location VARCHAR,
    name VARCHAR,
    genre VARCHAR,
    species VARCHAR,
    variety VARCHAR,
    circumference INTEGER,
    height INTEGER,
    stage VARCHAR,
    remarkable VARCHAR,
    geo_point_2d VARCHAR
);

-- load csv file in
-- replace with your own path
\COPY trees FROM '/Users/alexis/work/epitadb/data/les_arbres_upload_v02.csv' WITH CSV HEADER DELIMITER ',';

-- check
select * from trees order by random() limit 1;

\dt trees

-- create version table
create table version (
    id serial primary key,
    version varchar not null,
    description varchar,
    current BOOLEAN not null default false
);

-- insert version 01

insert into version (version, description, current) values ('01', 'loaded from csv; UTF8 and valid header;', TRUE);
-- --------------------------------
-- dump database
-- local
-- change username with your username
-- from terminal
-- --------------------------------

pg_dump --file "/Users/alexis/work/epitadb/data/treesdb_v01.08.sql.backup" \
--host "localhost" \
--port "5432" \
--username "alexis" \
--no-password \
--format=c \
--large-objects \
--clean \
--create \
--no-privileges \
--compress "9" \
--encoding "UTF8" \
--section=pre-data \
--section=data \
--section=post-data \
-d "treesdb_v01"


-- --------------------------------
-- restore database treesdb_v01 from this version treesdb_v01.08.sql.backup
-- connect to the remote or local database
-- start with fresh empty database treesdb_v01
-- --------------------------------
\c postgres
drop  database  if exists treesdb_v01 with(force) ;

CREATE DATABASE treesdb_v01
    WITH
    OWNER = epita
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

\c treesdb_v01

-- check that \d returns no relations

-- restore the tables from treesdb_v01.08.sql.backup
-- from the terminal, on the remote server

pg_restore -h 23.236.58.49 \
-d "treesdb_v01" \
-U epita \
--no-owner \
--no-privileges \
--no-data-for-failed-tables \
--section=pre-data \
--section=data \
--section=post-data \
--verbose \
--exit-on-error  \
--single-transaction \
"/Users/alexis/work/epitadb/data/treesdb_v01.08.sql.backup"

-- check that the data is there
psql -h 23.236.58.49 -U epita -d treesdb_v01 -c "select count(*) from trees;"
psql -h 23.236.58.49 -U epita -d treesdb_v01 -c "select * from trees order by random() limit 1;"



