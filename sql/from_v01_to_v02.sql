-- script to go from v01 to v02
-- add id primary key
-- changes data type for remarkable and geo_point_2d
-- drop columns location_type (signle value: Arbres) and number (empty)
-- add diameter flag
-- adds anomaly flag


"""
This script can be run in pgAdmin or in psql


"""



-- create database treesdb_v02 and restore from backup of treesdb_v01;
-- start fromm an empty database treesdb_v02
-- in psql
drop  database  if exists treesdb_v02 with(force) ;

CREATE DATABASE treesdb_v02
    WITH
    OWNER = epita
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- load backup of v01 into v02 as a starting point

pg_restore -h 23.236.58.49 \
-d "treesdb_v02" \
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
psql -h 23.236.58.49 -U epita -d treesdb_v02 -c "select count(*) from trees;"
psql -h 23.236.58.49 -U epita -d treesdb_v02 -c "select * from trees order by random() limit 1;"

-- or in psql
\d
select count(*) from trees;
select * from trees order by random() limit 1;


-- create new version
update version set current = FALSE;
insert into version (version, description, current) values ('02', 'data types; primary key', TRUE);


-- create primary key
alter table trees add column id serial primary key;

-- change remarkable to BOOLEAN with Null values

ALTER TABLE trees ADD COLUMN remarkable_bool BOOLEAN;

UPDATE trees
SET remarkable_bool =
    CASE
        WHEN remarkable = 'OUI' THEN TRUE
        WHEN remarkable = 'NON' THEN FALSE
        WHEN remarkable = '' THEN NULL
        ELSE NULL
    END;

ALTER TABLE trees DROP COLUMN remarkable;

ALTER TABLE trees RENAME COLUMN remarkable_bool TO remarkable;

-- check
select distinct(remarkable) from trees;
-- or
select count(*) as n, remarkable from trees group by remarkable order by n desc;


"""
Transform the geo_point_2d which is text : '(lat, long)'
into a POINT data type
"""
-- POINT

ALTER TABLE trees ADD COLUMN geolocation POINT;

-- Step 2: Update the new column with POINT data
UPDATE trees
SET geolocation = point(
    TRIM(SPLIT_PART(geo_point_2d, ',', 2))::float,
    TRIM(SPLIT_PART(geo_point_2d, ',', 1))::float
);

-- check
select id, geo_point_2d, geolocation from trees order by random() limit 1;
-- you should see the lat and long swapped but exact same values for each


-- Step 3 : Drop the old column if you no longer need it
ALTER TABLE trees DROP COLUMN geo_point_2d;

-- anomalies

-- add a diameter column calculated from the circumference with d = c / pi
alter table trees add column diameter float;

update trees
set diameter = circumference / PI();


-- drop columns that are not useful

alter table trees drop column location_type;
alter table trees drop column number;


-- dump db in treesdb_v02.01.sql.gz
-- replace epita with your username

pg_dump  -h 23.236.58.49 \
-d "treesdb_v02" \
-U epita \
--file "/Users/alexis/work/epitadb/data/treesdb_v02.01.sql.backup" \
--port "5432" \
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
--section=post-data

