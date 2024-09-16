"""
script to go from v02 to v03
denormalization
"""

-- set the host IP address when accessing the remote postgresql server
-- export PGHOST=$(gcloud compute instances describe epitadb-permanent --zone us-central1-c --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
-- echo $PGHOST


-- uncomment if you want 1) create the database v03 from scratch and restore the data from the data dump
"""
-- create database

DROP database if exists treesdb_v03 WITH(force) ;

CREATE DATABASE treesdb_v03
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- load treesdb_v02.01.sql.backup into treesdb_v03

pg_restore -h $PGHOST \
-d treesdb_v03 \
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
/Users/alexis/work/epitadb/data/treesdb_v02.01.sql.backup
"""

'''
psql -h $PGHOST -U epita -d treedb_v03 -c "select * from trees order by random() limit 1;"
'''

-- bump version table

update version set current = FALSE;
insert into version (version, description, current) values ('03', 'normalized', TRUE);

--  rename id_location to something less similar to location_id ... it will be confusing later on
alter table trees rename column id_location TO id_location_legacy;

-- -------------------------------------
-- start with simple denormalization :
-- domain and stage
-- -------------------------------------

create table tree_domains(
    id serial primary key,
    domain varchar
);

insert into tree_domains (domain)
select distinct domain from trees
where domain is not null;

ALTER TABLE trees ADD COLUMN domain_id INTEGER;

UPDATE trees t
SET domain_id = td.id
FROM tree_domains td
WHERE (t.domain = td.domain );

ALTER TABLE trees
ADD CONSTRAINT fk_tree_domain
FOREIGN KEY (domain_id)
REFERENCES tree_domains(id);

-- check that all domain in trees have a record in td.domain

select t.id
from trees t
join tree_domains td on td.id = t.domain_id
where t.domain != td.domain;

-- check that the query returns 0 rows
CREATE OR REPLACE FUNCTION assert_zero_rows(query TEXT)
RETURNS VOID AS $$
DECLARE
    row_count INT;
BEGIN
    -- Dynamically execute the input query and count the number of rows
    EXECUTE format('SELECT COUNT(*) FROM (%s) AS subquery', query) INTO row_count;

    -- Raise an exception if the query returns any rows
    IF row_count > 0 THEN
        RAISE EXCEPTION 'Assertion failed: Query returned % rows, but expected 0', row_count;
    ELSE
        RAISE NOTICE 'Assertion passed: Query returned 0 rows as expected.';
    END IF;
END;
$$ LANGUAGE plpgsql;

select assert_zero_rows('select t.id
from trees t
join tree_domains td on td.id = t.domain_id
where t.domain != td.domain');


-- now we can drop the column domain from trees

alter table trees drop column domain;

-- how do we now get the domain for a given tree ?
-- simple join

select t.*, td.*
from trees t
join tree_domains td on t.domain_id = td.id
order by random()
limit 1;

-- what is the differemce with this query ?

select t.*, td.*
from (
    select *
    from trees
    order by random()
    limit 1
) t
join tree_domains td on t.domain_id = td.id;

-- now let's do the same things for stage
-- don't forget to checking hte mapping before deleting the stage column

-------- stages
create table tree_stages(
    id serial primary key,
    stage varchar
);

insert into tree_stages (stage)
select distinct stage from trees
where stage is not null;

ALTER TABLE trees ADD COLUMN stage_id INTEGER;

UPDATE trees t
SET stage_id = ts.id
FROM tree_stages ts
WHERE (t.stage = ts.stage );

ALTER TABLE trees
ADD CONSTRAINT fk_tree_stage
FOREIGN KEY (stage_id)
REFERENCES tree_stages(id);

-- check
-- reuse the previous function

select assert_zero_rows('select t.id
from trees t
join tree_stages ts on ts.id = t.stage_id
where t.stage != ts.stage');



-- now drop the stage column
alter table trees drop column stage;

-- how do we get the stage and domain for a given random tree ?
select t.*, td.*, ts.*
from (
    select *
    from trees
    order by random()
    limit 1
) t
join tree_domains td on t.domain_id = td.id
join tree_stages ts on t.stage_id = ts.id
;



-- ---------------------------------------
-- taxonomy: names, genres, species, varieties
-- we keep the relations between names, genres, species and varieties
-- in a taxonomy table
-- that contains foreign keys to the other tables
-- ---------------------------------------

-- Step 1: Create the new tables
CREATE TABLE taxonomy (
    id SERIAL PRIMARY KEY,
    name_id INTEGER REFERENCES tree_names(id),
    genre_id INTEGER REFERENCES tree_genres(id),
    species_id INTEGER REFERENCES tree_species(id),
    variety_id INTEGER REFERENCES tree_varieties(id),
    UNIQUE (name_id, genre_id, species_id, variety_id)
);



CREATE TABLE tree_names (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE tree_genres (
    id SERIAL PRIMARY KEY,
    genre VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE tree_species (
    id SERIAL PRIMARY KEY,
    species VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE tree_varieties (
    id SERIAL PRIMARY KEY,
    variety VARCHAR(255) UNIQUE NOT NULL
);

-- Step 2: Insert data into the new tables
-- How to modify the query so that the names, genres, ...
-- in the tree_names, tree_genres tables are ordered by their frequency in the trees table ?
-- or ordered in the alphabetiocal order ?


INSERT INTO tree_names (name)
SELECT DISTINCT name FROM trees
WHERE name IS NOT NULL
order by name asc;

-- INSERT INTO tree_genres (genre)
-- SELECT DISTINCT genre FROM trees
-- WHERE genre IS NOT NULL;

-- becomes
INSERT INTO tree_genres (genre)
SELECT genre
FROM (
    SELECT genre, COUNT(*) as frequency
    FROM trees
    WHERE genre IS NOT NULL
    GROUP BY genre
    ORDER BY frequency DESC
) as ordered_genres;


INSERT INTO tree_species (species)
SELECT DISTINCT species FROM trees
WHERE species IS NOT NULL
order by species asc;

INSERT INTO tree_varieties (variety)
SELECT DISTINCT variety FROM trees
WHERE variety IS NOT NULL
order by variety asc;


-- Step 3: Insert data into the taxonomy table
INSERT INTO taxonomy (name_id, genre_id, species_id, variety_id)
SELECT DISTINCT
    n.id AS name_id,
    g.id AS genre_id,
    s.id AS species_id,
    v.id AS variety_id
FROM
    trees t
LEFT JOIN tree_names n ON t.name = n.name
LEFT JOIN tree_genres g ON t.genre = g.genre
LEFT JOIN tree_species s ON t.species = s.species
LEFT JOIN tree_varieties v ON t.variety = v.variety;

-- Step 4: Add taxonomy_id column to the trees table
ALTER TABLE trees ADD COLUMN taxonomy_id INTEGER;

-- Step 5: Update the trees table with the corresponding taxonomy_id
UPDATE trees t
SET taxonomy_id = tt.id
FROM taxonomy tt
LEFT JOIN tree_names n ON tt.name_id = n.id
LEFT JOIN tree_genres g ON tt.genre_id = g.id
LEFT JOIN tree_species s ON tt.species_id = s.id
LEFT JOIN tree_varieties v ON tt.variety_id = v.id
WHERE
    t.name = n.name
    AND t.genre = g.genre
    AND t.species = s.species
    AND t.variety = v.variety;

-- Step 6: Add foreign key constraint to the trees table
ALTER TABLE trees
ADD CONSTRAINT fk_taxonomy
FOREIGN KEY (taxonomy_id)
REFERENCES taxonomy(id);

-- step check

select assert_zero_rows('
select t.*
from trees t
join taxonomy tt on tt.id = t.taxonomy_id
join tree_names tn on tn.id = tt.name_id
where t.name != tn.name');

select assert_zero_rows('
select t.*
from trees t
join taxonomy tt on tt.id = t.taxonomy_id
join tree_species tn on tn.id = tt.species_id
where t.species != tn.species');



-- Step 7: Remove the old columns from the trees table
ALTER TABLE trees
DROP COLUMN name,
DROP COLUMN genre,
DROP COLUMN species,
DROP COLUMN variety;


-- query
-- how to order the variety by their freqnecy in the trees table

SELECT
    tv.variety,
    COUNT(t.id) AS variety_count
FROM
    trees t
JOIN
    taxonomy tax ON t.taxonomy_id = tax.id
JOIN
    tree_varieties tv ON tax.variety_id = tv.id
GROUP BY
    tv.variety
ORDER BY
    variety_count DESC;



-- -------------------------------------
-- normalize addresses and geolocations
-- in the same table: locations
-- -------------------------------------


-- step 1: create the location address
create table locations (
    id serial primary key,
    suppl_address  varchar,
    address        varchar,
    arrondissement varchar,
    geolocation    varchar
);


-- Step 2: Copy data from trees table to the new locations table

INSERT INTO locations (suppl_address, address, arrondissement, geolocation)
SELECT  suppl_address, address, arrondissement, geolocation
FROM trees
WHERE suppl_address IS NOT NULL
   OR address IS NOT NULL
   OR arrondissement IS NOT NULL
   OR geolocation IS NOT NULL;

-- Step 3: Add a location_id column to the trees table
ALTER TABLE trees ADD COLUMN location_id INTEGER;

-- step 4
-- connect location_id to location.id
-- it is not sufficient to connect on equality of geolocation sine there are multiple sequal geolocations (12 of them)
-- so we need identification on the whole address

SELECT COUNT(*) as tree_count, geolocation::text
FROM locations
GROUP BY geolocation::text
HAVING COUNT(*) > 1
ORDER BY tree_count DESC;


-- a quick check shows that geolocation duplicates all have the same address
select * from locations where geolocation::text in (SELECT  geolocation::text                                                   FROM locations                                                                                                                                GROUP BY geolocation::text
HAVING COUNT(*) > 1) order by geolocation::text asc;

-- so we can delete locations duplicates with
WITH numbered_duplicates AS (
    SELECT id, geolocation,
           ROW_NUMBER() OVER (PARTITION BY geolocation::text ORDER BY id) as row_num
    FROM locations
    WHERE geolocation::text IN (
        SELECT geolocation::text
        FROM locations
        GROUP BY geolocation::text
        HAVING COUNT(*) > 1
    )
)
DELETE FROM locations
WHERE id IN (
    SELECT id
    FROM numbered_duplicates
    WHERE row_num > 1
);


-- and check
SELECT COUNT(*) as tree_count, geolocation::text
FROM locations
GROUP BY geolocation::text
HAVING COUNT(*) > 1
ORDER BY tree_count DESC;

-- should return 0
-- and the trees table has 12 more rows than the locations table

"""
another way to avoind duplicates
would have been to cast geolocation as text
and use
    insert from select distinct
in the query above and then to recast geolocation as point
"""

-- so now we can associate trees location_id with location.id based on geolocation
UPDATE trees t
SET location_id = l.id
FROM locations l
WHERE (t.geolocation::text = l.geolocation::text );

-- verify that 12 rows in trees have duplicate location_id
select count(*) as n, location_id from trees group by location_id having count(*) > 1;

-- finally add foreign key constraint in the trees db
ALTER TABLE trees
ADD CONSTRAINT fk_location
FOREIGN KEY (location_id)
REFERENCES locations(id);


-- before dropping original columns make sure that the addresses and geolocation match
-- this query should return 0 rows
select assert_zero_rows('
select t.*, l.*
from trees t
join locations l on l.id = t.location_id
where t.geolocation::text != l.geolocation::text
limit 10');

-- and drop location columns from trees
alter table trees drop column address;
alter table trees drop column suppl_address;
alter table trees drop column arrondissement;
alter table trees drop column geolocation;


--- measures
"""
Let's keep the measures as they are in the trees forest

what follows is an optional way to normalize the measures
which would really make sense if a tree had multiple measures
taken at different times.
since trees only have one set of measures (except for 2 duplicates over the whole set)
it does not make sense to normalize.


-- Step 1: Create the measures table
CREATE TABLE tree_measures (
    id SERIAL PRIMARY KEY,
    tree_id INTEGER REFERENCES trees(id),
    height INTEGER,
    diameter DOUBLE PRECISION,
    circumference INTEGER,
    measurement_date DATE DEFAULT CURRENT_DATE,
    UNIQUE (tree_id, measurement_date)
);

-- Step 2: Insert existing data into the measures table
INSERT INTO tree_measures (tree_id, height, diameter, circumference)
SELECT id, height, diameter, circumference
FROM trees
WHERE height IS NOT NULL OR diameter IS NOT NULL OR circumference IS NOT NULL;


-- Step 4 (: Create an index on tree_id for better query performance
CREATE INDEX idx_tree_measures_tree_id ON tree_measures(tree_id);


-- Step 3: Remove measurement columns from the trees table
ALTER TABLE trees
DROP COLUMN height,
DROP COLUMN diameter,
DROP COLUMN circumference;
"""



-- -----------------------------
-- dump resulting database as treesdb_v03.01.sql.backup
-- -----------------------------

-- dump db in treesdb_v02.01.sql.gz
-- replace epita with your username

pg_dump  -h $PGHOST \
-d "treesdb_v03" \
-U epita \
--file "/Users/alexis/work/epitadb/data/treesdb_v03.01.sql.backup" \
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

-- -----------------------------
-- if you need to restore treesdb_v03.01.sql.backup into an empty treesdb_v03 database
-- -----------------------------


pg_restore -h $PGHOST \
-d treesdb_v03 \
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
/Users/alexis/work/epitadb/data/treesdb_v03.01.sql.backup
