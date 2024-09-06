# Explore the trees dataset
In this document we explore the trees dataset that has been loaded from the csv file or the sql dump.


## Goal
The trees dataset is not perfect. there are anomalies, missing data 
The table data types is not optimal and we are missing a primary key

This is a good reflection of real world datasets that are never perfect. 

In this document we get a sens of the data, deal with some anomalies and transform the table with more appropriate dataset.
We also leverage the postGIS extension for spatial data.

# data analysis

Let's do some data analysis of the dataset.

Looking at some samples with

```
select * from trees order by random() limit 1;
```

We see that we have 

- some categorical columns related to the location : domain, arrondissement
- categorical columns related to the nature of the tree : name, genre, species, variety, 
- and also : stage, 
- dimensions of the tree : height and circumference
- columns related to the location of the tree: address, suppl_address, number, ...
- a ```remarquable``` flag
- and geo location : geo_point_2d with latitude and longitude of each tree


Let's query the tree table and get a feeling for the values of the different columns

- how many trees per ```domain``` or ```arrondissement```
- and stage, genre, species ...
- how many trees are remarquable ?
- do all trees have a height and a circonference ?
- what's the average height for different domain, stage or remarquable

any other thing you can think of ?

# Where's the primary key ?

The table loaded from a csv has no primary key. idbase seems like a candidate.

but could the ```idbase``` column be a primary key

## What's a primary key and what is it used for ?

A **primary key** in SQL (Structured Query Language) is a unique identifier for each record (or row) in a table. 

Its main purpose is to ensure that each record in the table can be uniquely identified. 

A primary key is a constraint that enforces uniqueness and non-nullability for the column or columns it is applied to.

Having a primary key allows databases to index the table more efficiently, making searches and retrievals faster when accessing records by their primary key value.

In relational databases, primary keys are often used in conjunction with foreign keys in other tables. 
A **foreign key** is a field (or a combination of fields) that references a primary key in another table.

A column is a good candidate for a primary key if:

- It contains unique values for each row.
- It does not contain any NULL values.
- It remains consistent and does not change often.
    
would the idbase column be a good candidate for  primary key ?
can it be serial ?

_Write a query to find out if some values of idbase have more than 2 rows_

**solution:**

```
SELECT idbase, COUNT(*)
FROM trees
GROUP BY idbase
HAVING COUNT(*) > 1;
```

returns 2 rows

maybe these are duplicates 

select the trees that have duplicates idbase with 

```
select * from trees where idbase in (select idbase from 
(
SELECT idbase, COUNT(*)
FROM trees
GROUP BY idbase
HAVING COUNT(*) > 1
)) order by idbase asc;
```

the trees have the exact same geo loc but different heights / circs

since there's no way to know which is the tree with true values we can delete all 4 rows

- now does the idbase have null values ?

Can we transform idbase into a serial primary key ?
or should we create a primary key from scratch ?

---
# SERIAL

A SERIAL column in PostgreSQL is an auto-incrementing integer type that assigns a unique sequential value to each row. To ensure that your idbase column can be converted to SERIAL, it must:

- Have only unique values: No duplicates.
- Have no NULL values: SERIAL cannot have NULL values.
- Contain integer values: The column must contain numeric data compatible with an integer type.
- Contain a contiguous sequence (optional): While not required, a typical SERIAL column generates values sequentially, so a check for contiguous values can help if you're aiming to preserve the order.

---

so here we have 2 options 
- add a new column ```id``` as SERIAL primary key
- transform the ```idbase``` as SERIAL primary key

The second option requires to manually create a sequence while the 1st option creates the sequence automatically 

but we notice that the idbase are not sequential 
- see max and min 
so the easiest solution is to create a new serial primary key

```sql
alter table trees add COLUMN id SERIAL PRIMARY KEY;
```

creating a primary key also creates a sequence ;

\d returns 

```treesdb=# \d```

             
 Schema |     Name     |   Type   | Owner  
--------+--------------+----------+--------
 public | trees        | table    | alexis
 public | trees_id_seq | sequence | alexis

---
# Postgres Sequence
a sequence is a special database object designed to generate a sequence of unique, incremental numbers. It is commonly used to create auto-incrementing values, typically for columns like primary keys.


- Unique: Each number in the sequence is guaranteed to be unique.
- Incremental: The sequence can increment (or decrement) by a specified value.
- Independent Object: A sequence is a separate object in the database and is not directly tied to any table or column, though it is often associated with a column (like SERIAL or BIGSERIAL columns).
- NEXTVAL Function: To get the next value in the sequence, you call nextval('sequence_name'), which increments the sequence and returns the next number.
- START, INCREMENT, and MAXVALUE: You can specify the starting value, how much to increment by, and an optional maximum value for the sequence.

---


which creates a trees_id_seq 

```
\d+ trees_id_seq
```

  Type   | Start | Minimum |  Maximum   | Increment | Cycles? | Cache 
---------+-------+---------+------------+-----------+---------+-------
 integer |     1 |       1 | 2147483647 |         1 | no      |     1
Owned by: public.trees.id

and 
```
\d+ trees
```

    Column     |       Type        | Collation | Nullable |              Default              
----------------+-------------------+-----------+----------+-----------------------------------
 id             | integer           |           | not null | nextval('trees_id_seq'::regclass)



notice the ```nextval('trees_id_seq'::regclass)``` which increments the counter in  the sequence each time it is called

also notice the new index 

```
Indexes:
    "trees_pkey" PRIMARY KEY, btree (id)
```

We can keep the idbase for future references but we will use id as the primary key.


## Transforming the column types
all columns are varchar except for the height and circonference

that does not make sense for some columns : remarquable, and geo_point_2d 

- remarquable should be a boolean
how do we transform the column which has NON, OUI or empty string as boolean : t, f and null

ALTER TABLE trees ADD COLUMN remarquable_bool BOOLEAN;

UPDATE trees
SET remarquable_bool = 
    CASE 
        WHEN remarquable = 'OUI' THEN TRUE
        WHEN remarquable = 'NON' THEN FALSE
        WHEN remarquable = '' THEN NULL
        ELSE NULL
    END;

ALTER TABLE trees DROP COLUMN remarquable;

ALTER TABLE trees RENAME COLUMN remarquable_bool TO remarquable;




- geo location is a varchar

we have a choice to use a native POINT data column or a GeoDIs geography data type

comparison

| Feature | POINT | GEOGRAPHY |
|---------|-------|-----------|
| Coordinate System | Flat, Cartesian (x, y) | Spherical (longitude, latitude) |
| Earth's Curvature | Not accounted for | Accounted for |
| Distance Calculations | Euclidean (straight line on flat plane) | Great circle (curved line on Earth's surface) |
| Accuracy over Large Distances | Less accurate | Maintains global accuracy |
| Performance | Generally faster for basic operations | May be slower but more accurate for geographic calculations |
| Use Cases | Local, small-scale applications (e.g., floor plans, 2D games) | Global, large-scale geographic applications (e.g., GPS, GIS) |
| Additional Functionality | Limited to basic geometric operations | Extensive GIS functions available through PostGIS |
| Data Representation | Simple (x, y) coordinates | Complex spheroidal calculations |
| Spatial Reference System | Typically assumes a flat plane | Supports various geographic coordinate systems (e.g., WGS84) |
| Storage Size | Smaller | Larger due to additional metadata |


Let's use the extension GeoDIS

first we need to install the POSt GIs extension if it's not installed yet

SELECT * FROM pg_extension WHERE extname = 'postgis';

if its hows 0 rows you need to install it on the server and then activate it 

### install on mac
brew install postgis

brew restart

### install on Windows
Install PostGIS:

Use the Stack Builder application that comes with PostgreSQL.
Launch Stack Builder and select your PostgreSQL installation.
In the "Spatial Extensions" section, select PostGIS.
Follow the prompts to download and install PostGIS.

Then in the psql console activate the extension with 
CREATE EXTENSION postgis;



### transform the lat ling into a GEOGRAPHY 

ALTER TABLE trees ADD COLUMN geo_point_geography GEOGRAPHY(POINT, 4326);

-- Update the new column with data from the existing VARCHAR column
UPDATE trees
SET geo_point_geography = ST_SetSRID(ST_MakePoint(
    SPLIT_PART(geo_point_2d, ',', 2)::float, 
    SPLIT_PART(geo_point_2d, ',', 1)::float
), 4326)::geography;

CREATE INDEX idx_trees_geography ON trees USING GIST (geo_point_geography);

## Some elements about PostgIS

we won't go into details about PostGIS

here is the site and a list of tutorials if you need to go deeper

https://postgis.net/documentation/training/ 


## Closest trees

Now we can find the closest trees to a given lat long location

you can use that address to lat long converter 
https://www.latlong.net/convert-address-to-lat-long.html

and the query 

```
WITH given_tree AS (
  SELECT id, geo_point_geography
  FROM trees
  WHERE id = 1234  -- Replace with the ID of your reference tree
)
SELECT t.id, t.geo_point_geography, 
       ST_Distance(t.geo_point_geography, gt.geo_point_geography) AS distance
FROM trees t, given_tree gt
WHERE t.id != gt.id
ORDER BY t.geo_point_geography <-> gt.geo_point_geography
LIMIT 9;  -- N-1, as we're excluding the reference tree

```



We use ST_Distance() function to calculate the great-circle distance between two points on the Earth's surface.
The distance is returned in meters.
We still use the <-> operator in the ORDER BY clause as a fast approximation for initial ordering, which PostGIS then refines.

The query is a CTE

-> modify the query so that it takes a lat long instead of a tree_id

-- Query to find N nearest trees given a latitude and longitude
-- Using a CTE to define the location

transform a set of lat long to a geography type with 
```SELECT ST_SetSRID(ST_MakePoint(-74.0060, 40.7128), 4326)::geography AS geog```

so the query becomes 

```
WITH location AS (
    SELECT ST_SetSRID(ST_MakePoint(-74.0060, 40.7128), 4326)::geography AS geog
)
SELECT 
    t.id,
    ST_Distance(t.geo_point_geography, location.geog) AS distance_meters,
    ST_Y(t.geo_point_geography::geometry) AS tree_lat,
    ST_X(t.geo_point_geography::geometry) AS tree_long
FROM 
    trees t,
    location
ORDER BY 
    t.geo_point_geography <-> location.geog
LIMIT 5;
```


## Some common queries 

we want to set aside trees that have anomalies

find the trees that are too tall
create a new column boolean that will hold TRUE is the tree is crazy tall (obvious anomaly)

same thing for the circumference
but to find anomalies in the circonference, first create a float column with diameter

and find tress that have a insanely high diameter
update the anomaly column with these trees

also set the anomaly to truye for duplicates of idbase

are there other anomalies such as duplicates addresses ?

# Recap

The table laoded from the csv / sq dump was lacking a primary key, prper datatypes and had some anomalies
we also activated the spatial postgis extension so that we can select trees based on their locations 

The current table is much more clean and ready for production



