-- script to go from v01 to v02
--

-- create database
CREATE DATABASE treesdb_v02
    WITH
    OWNER = alexis
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- load v01 into v02
pg_restore --username "alexis" --no-password --dbname "treesdb_v02" --section=pre-data --section=data --section=post-data --verbose "/Users/alexis/work/epitadb/data/treesdb_v01.sql.gz"

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

-- PostGIS



-- POINT

ALTER TABLE trees ADD COLUMN geolocation POINT;

-- Step 2: Update the new column with POINT data
UPDATE trees
SET geolocation = point(
    TRIM(SPLIT_PART(geo_point_2d, ',', 2))::float,
    TRIM(SPLIT_PART(geo_point_2d, ',', 1))::float
);


-- Step 3 (Optional): Drop the old column if you no longer need it
-- ALTER TABLE tree DROP COLUMN geo_point_2d;

-- anomalies

-- diameter
alter table trees add column diameter float;

update trees
set diameter = circumference / PI();
