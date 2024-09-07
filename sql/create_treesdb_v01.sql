-- script to load the data from the csv file les_arbres_upload_v02.csv
-- file is UTF8, proper comma delimiter and line returns, proper headers

-- create database
CREATE DATABASE treesdb_01
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
-- --------------------------------
-- General :
-- filename: /Users/alexis/work/epitadb/data/treesdb_v01.sql.gz
-- format: custom
-- compression ratio: 9
-- Encoding: UTF8

-- Data options: all 3 sections : pre data, data and post data

-- Query options: use insert commands
-- Others: disable verbose message
-- --------------------------------

-- CLI:
-- pg_dump --file "/Users/alexis/work/epitadb/data/treesdb_v01.sql.gz" --host "localhost" --port "5432" --username "alexis" --no-password --format=c --large-objects --compress "9" --encoding "UTF8" --section=pre-data --section=data --section=post-data --inserts "treesdb_01"
--

-- --------------------------------
-- restore database from this version
-- --------------------------------
\c postgres
drop database treesdb_01;

CREATE DATABASE treesdb_v01
    WITH
    OWNER = alexis
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

\c treesdb_v01
-- check
-- restore
-- pg_restore --username "alexis" --no-password --dbname "treesdb_v01" --section=pre-data --section=data --section=post-data --verbose "/Users/alexis/work/epitadb/data/treesdb_v01.sql.gz"

