-- script to go from v03 to v04
--

-- create database
CREATE DATABASE treesdb_v03
    WITH
    OWNER = alexis
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- load v03
pg_restore --host "localhost" --port "5432" --username "alexis" --no-password --dbname "treesdb_v03" --verbose "/Users/alexis/work/epitadb/data/treesdb_v03.sql.gz"

-- bump version

update version set current = FALSE;
insert into version (version, description, current) values ('03', 'normalized', TRUE);

-- also rename id_location to something less similar to location_id ...
alter table trees rename column id_location id_location_legacy;

-- normalize addresses

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

-- so we can delete locations duplictaes with
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

-- another way to avoind duplicates would have been to cast geolocation as text and use insert from select distinct in the query above and then to recast geolocation as point

-- so now we can associate trees location_id with location.id based on geolocation
UPDATE trees t
SET location_id = l.id
FROM locations l
WHERE (t.geolocation::text = l.geolocation::text );

-- verify that 12 rows in trees have duoplicate location_id
select count(*) as n, location_id from trees group by location_id having count(*) > 1;

-- finally add foreign key constraint in the trees db
ALTER TABLE trees
ADD CONSTRAINT fk_location
FOREIGN KEY (location_id)
REFERENCES locations(id);


-- but dropping original columns make sure that the addresses and geolocation match
-- this query should return 0 rows

select t.*, l.*
from trees t
join locations l on l.id = t.location_id
where t.geolocation::text != l.geolocation::text
limit 10;

-- and drop location columns from trees
alter table trees drop column address;
alter table trees drop column suppl_address;
alter table trees drop column arrondissement;
alter table trees drop column geolocation;


-- domain and stage
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



select t.*
from trees t
join tree_domains td on td.id = t.domain_id
where t.domain != td.domain;

alter table trees drop column domain;

--------
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



select t.*
from trees t
join tree_stages ts on ts.id = t.stage_id
where t.stage != ts.stage;

alter table trees drop column stage;

-- taxonomy

-- Step 1: Create the new tables
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

CREATE TABLE tree_taxonomy (
    id SERIAL PRIMARY KEY,
    name_id INTEGER REFERENCES tree_names(id),
    genre_id INTEGER REFERENCES tree_genres(id),
    species_id INTEGER REFERENCES tree_species(id),
    variety_id INTEGER REFERENCES tree_varieties(id),
    UNIQUE (name_id, genre_id, species_id, variety_id)
);

-- Step 2: Insert data into the new tables
INSERT INTO tree_names (name)
SELECT DISTINCT name FROM trees
WHERE name IS NOT NULL;

INSERT INTO tree_genres (genre)
SELECT DISTINCT genre FROM trees
WHERE genre IS NOT NULL;

INSERT INTO tree_species (species)
SELECT DISTINCT species FROM trees
WHERE species IS NOT NULL;

INSERT INTO tree_varieties (variety)
SELECT DISTINCT variety FROM trees
WHERE variety IS NOT NULL;

-- Step 3: Insert data into the tree_taxonomy table
INSERT INTO tree_taxonomy (name_id, genre_id, species_id, variety_id)
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

-- Step 4: Add tree_taxonomy_id column to the trees table
ALTER TABLE trees ADD COLUMN tree_taxonomy_id INTEGER;

-- Step 5: Update the trees table with the corresponding tree_taxonomy_id
UPDATE trees t
SET tree_taxonomy_id = tt.id
FROM tree_taxonomy tt
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
ADD CONSTRAINT fk_tree_taxonomy
FOREIGN KEY (tree_taxonomy_id)
REFERENCES tree_taxonomy(id);

-- step check

select t.*
from trees t
join tree_taxonomy tt on tt.id = t.tree_taxonomy_id
join tree_names tn on tn.id = tt.name_id
where t.name != tn.name;

select t.*
from trees t
join tree_taxonomy tt on tt.id = t.tree_taxonomy_id
join tree_species tn on tn.id = tt.species_id
where t.species != tn.species;



-- Step 7: Remove the old columns from the trees table
ALTER TABLE trees
DROP COLUMN name,
DROP COLUMN genre,
DROP COLUMN species,
DROP COLUMN variety;


--- measures

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
