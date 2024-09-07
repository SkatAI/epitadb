remarkable# Improving the trees dataset
In this document we explore and improve the trees dataset that has been loaded from a sql dump.


Here are the columns of the tree table

     Column     |       Type        | Collation | Nullable | Default | Storage  | Compression | Stats target | Description 
----------------+-------------------+-----------+----------+---------+----------+-------------+--------------+-------------
 idbase         | integer           |           |          |         | plain    |             |              | 
 location_type  | character varying |           |          |         | extended |             |              | 
 domain         | character varying |           |          |         | extended |             |              | 
 arrondissement | character varying |           |          |         | extended |             |              | 
 suppl_address  | character varying |           |          |         | extended |             |              | 
 number         | character varying |           |          |         | extended |             |              | 
 address        | character varying |           |          |         | extended |             |              | 
 id_location    | character varying |           |          |         | extended |             |              | 
 name           | character varying |           |          |         | extended |             |              | 
 genre          | character varying |           |          |         | extended |             |              | 
 species        | character varying |           |          |         | extended |             |              | 
 variety        | character varying |           |          |         | extended |             |              | 
 circumference  | integer           |           |          |         | plain    |             |              | 
 height         | integer           |           |          |         | plain    |             |              | 
 stage          | character varying |           |          |         | extended |             |              | 
 geo_point_2d   | character varying |           |          |         | extended |             |              | 
 remarkable    | boolean           |           |          |         | plain    |             |              | 



# Goal
The trees dataset is not perfect. there are anomalies, missing data 

The table data types is not optimal for some columns and we are missing a primary key

This is a good reflection of real world datasets that are never perfect. 

In this document we get a sense of the data, deal with some anomalies and transform the table with more appropriate data types.

We also leverage the postGIS extension for spatial data.

# data analysis

Let's do some data analysis of the dataset.

Looking at some samples with

```sql
select * from trees order by random() limit 1;
```

     Column     |       value
----------------+-------------------
idbase         | 273252
location_type  | Arbre
domain         | Alignement
arrondissement | PARIS 18E ARRDT
suppl_address  | 
number         | 
address        | RUE DE LA CHAPELLE
id_location    | 000602007
name           | Tilleul
genre          | tilia
species        | cordata
variety        | Greenspire
circumference  | 34
height         | 5
stage          | Jeune (arbre)
geo_point_2d   | 48.89291084026716, 2.359807495821241
remarkable    | f



We see that we have 

- some categorical columns related to the location : domain, arrondissement
- categorical columns related to the nature of the tree : name, genre, species, variety, 
- and also : stage, 
- dimensions of the tree : height and circumference (in meters)
- columns related to the location of the tree: address, suppl_address, number, ...
- a ```remarkable``` flag
- and geo location : geo_point_2d with latitude and longitude of each tree


Let's query the tree table and get a feeling for the values of the different columns

- how many trees per ```domain``` or ```arrondissement```
- how many trees per stage, genre, species ...
- how many trees are remarkable ?
- do all trees have a height and a circumference ?
- what's the average height for different domain, stage or remarkable

any other thing you can think of ?

# Where's the primary key ?

The table loaded from a csv has no primary key although ```idbase``` seems like a candidate.

Could the ```idbase``` column be a primary key ?

# What's a primary key and what is it used for ?

A **primary key** in SQL (Structured Query Language) is a unique identifier for each record (or row) in a table. 

Its main purpose is to ensure that each record in the table can be uniquely identified. 

A primary key is a constraint that enforces **uniqueness** and **non-nullability** for the column or columns it is applied to.

Having a primary key allows databases to index the table more efficiently, making searches and retrievals faster when accessing records by their primary key value.

In relational databases, primary keys are often used in conjunction with **foreign keys** in other tables. 

A **foreign key** is a field (or a combination of fields) that references a primary key in another table.

A column is a good candidate as a primary key if:

- It contains unique values for each row.
- It does not contain any NULL values.
- It remains consistent and does not change often.

### SERIAL

A primary key is usually also SERIAL. 

>In PostgreSQL, SERIAL is a special data type used for **auto-incrementing** integer columns, commonly employed for primary keys.



> When you define a column with SERIAL, PostgreSQL automatically creates a **sequence** and sets it up so that each new row gets the next value from this sequence.
    
--- 
Based on this definition,  the ```idbase``` column be a good candidate for primary key ?

Also, can it be serial ? 


Let's check uniqueness of the values first : 

_Write a query to find out if some values of idbase have more than 2 rows_

**solution:**

```sql
SELECT idbase, COUNT(*)
FROM trees
GROUP BY idbase
HAVING COUNT(*) > 1;
```

This query returns 2 rows

maybe these are exact duplicates of trees, let's check

You can select the trees that have duplicates ```idbase``` with 

```sql
select * from trees where idbase in (select idbase from 
(
SELECT idbase, COUNT(*)
FROM trees
GROUP BY idbase
HAVING COUNT(*) > 1
)) order by idbase asc;
```

These trees have the exact same data except for heights and circumference which are  different. At this point there's no way to know which is the tree with the true values.

So to make ```idbase``` the primary we would have to delete the duplicates.

- Check for null values : does the idbase have null values ?

- are the ```idbase``` values sequential ? (check min and max and total count of trees)

Note: a SERIAL primary does not have to be sequential. 


So we have 2 options 

- add a new column ```id``` as SERIAL primary key 
- transform the ```idbase``` as SERIAL primary key

The second option requires to 1) manually create a sequence, 2) delete some records. 

The 1st option is the easiest one as  create the sequence automatically 

so the easiest solution is to create a new serial primary key

```sql
alter table trees add COLUMN id SERIAL PRIMARY KEY;
```

As expected, creating a primary key also creates a sequence ;


```bash
treesdb=# \d

             
 Schema |     Name     |   Type   | Owner  
--------+--------------+----------+--------
 public | trees        | table    | alexis
 public | trees_id_seq | sequence | alexis
```

---

# Postgres Sequence
> a sequence is a special database object designed to generate a sequence of unique, incremental numbers. It is commonly used to create auto-incrementing values, typically for columns like primary keys.


- **Unique**: Each number in the sequence is guaranteed to be unique.
- **Incremental**: The sequence can increment (or decrement) by a specified value.
- **Independent Object**: A sequence is a separate object in the database and is not directly tied to any table or column, though it is often associated with a column (like SERIAL or BIGSERIAL columns).
- **NEXTVAL Function**: To get the next value in the sequence, you call nextval('sequence_name'), which increments the sequence and returns the next number.
- **START, INCREMENT, and MAXVALUE**: You can specify the starting value, how much to increment by, and an optional maximum value for the sequence.

---



```sql
\d+ trees_id_seq

  Type   | Start | Minimum |  Maximum   | Increment | Cycles? | Cache 
---------+-------+---------+------------+-----------+---------+-------
 integer |     1 |       1 | 2147483647 |         1 | no      |     1
Owned by: public.trees.id
```

and
 
```sql
\d+ trees

    Column     |       Type        | Collation | Nullable |              Default              
----------------+-------------------+-----------+----------+-----------------------------------
 id             | integer           |           | not null | nextval('trees_id_seq'::regclass)
```



notice the ```nextval('trees_id_seq'::regclass)``` which increments the counter in  the sequence each time it is called

also notice the new index 

```sql
Indexes:
    "trees_pkey" PRIMARY KEY, btree (id)
```

We can keep the ```idbase``` for future references but we will use ```id``` as the primary key.


# Improving the column types
At this point, all columns are ```varchar``` except for the height and circumference

that does not make sense for  columns such as:  ```remarkable```, and geo_point_2d (latitude and longitude)

- ```remarkable``` should be a boolean

How to transform the column which has 'NON', 'OUI; or '' (empty string) as boolean : t, f and null

```sql
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
```


- ```geo_point_2d``` is a also varchar

```geo_point_2d``` holds the latitude and longitude of the trees. We could transform ```geo_point_2d``` as an array of floats. However there are specific data types for geo localisation. Using the proper data type will allow us to more easily carry out calculations specific to locations. For instance find the nearest trees, or calculate the distance between  trees.

We have a choice to use a native **POINT** data column (available by default in postgreSQL) or a **PostGIS** geography data type (needs the PostGIS extension)

### Comparison between POINT and GEOGRAPHY

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


Let's use the extension PostGIS. 

we won't go into details about PostGIS

here is the site and a list of tutorials if you need to go deeper

[postgis documentation](https://postgis.net/documentation/training/) 


First we need to install the PostGIS extension if it's not installed yet. 

Check if PostGIS is installed or not with

```sql
SELECT * FROM pg_extension WHERE extname = 'postgis';
```

if this returns 0 rows you need to install PostGIS on the server and then activate it 

### install PostGIS on mac

```shell
brew install postgis
brew restart
```


### Note

Installing postGIS with ```brew install postgis``` on Mac, requires postgres14. 
If you have already installed postgres16, you'd have to install postgres14 and things will probably become messy

An alternative is to use the Postgres app https://postgresapp.com/ that bundles postgres164 and postgis 3.4. 

I haven't tried. This will probably also require to uninstall your the postgres already installed.

So no quick and easy way to install postgis with postgres16 on Mac at this point.

If you're in that situation (existing postgres16 on Mac) just switch to using the postgres native Point data type. see below 

### install PostGIS  on Windows

Install PostGIS:

1. Use the Stack Builder application that comes with PostgreSQL.
2. Launch Stack Builder and select your PostgreSQL installation.
3. In the "Spatial Extensions" section, select PostGIS.
4. Follow the prompts to download and install PostGIS.

### install PostGIS on Ubuntu or Debian

first, always satrt with 
```shell
sudo apt update 
```

Check the postgreSQL version with

```shell
psql --version
```

Then (replace with the version of postgreSQL you see)

```shell
apt search postgresql-16 | grep postgis
```

and install the version that was found

```shell
sudo apt install postgresql-16-postgis-3
```

### activate the extension
In the psql console activate the extension with:

```sql
CREATE EXTENSION postgis;
```


now connect with psql and check that postGis is installed

```sql
SELECT * FROM pg_extension WHERE extname = 'postgis';
```



# Transform the geo_point_2d from varchar to GEOGRAPHY 

Add a column with the right data type

```sql
ALTER TABLE trees ADD COLUMN geo_point_geography GEOGRAPHY(POINT, 4326);
```

Update the new column with data from the existing ```geo_point_2d``` column
```sql
UPDATE trees
SET geo_point_geography = ST_SetSRID(ST_MakePoint(
    SPLIT_PART(geo_point_2d, ',', 2)::float, 
    SPLIT_PART(geo_point_2d, ',', 1)::float
), 4326)::geography;
```

and create an index 
```sql
CREATE INDEX idx_trees_geography ON trees USING GIST (geo_point_geography);
```


## Closest trees

Now we can find the N (=10) closest trees to a given tree


```sql
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
LIMIT 9;  -- 10-1, as we're excluding the reference tree
```


We use ```ST_Distance()``` function to calculate the great-circle distance between two points on the Earth's surface.
The distance is returned in meters.

We also use the ```<->``` operator in the ORDER BY clause as a fast approximation for initial ordering, which PostGIS then refines.

Note the structure of the query. 

```sql

with relation_name as (
    select statement
)
select columns from table, relation_name 


```


The query is a CTE or Common Table Expressions

-> modify the query so that it takes a lat long instead of a tree_id

you can use that address to lat long converter 
https://www.latlong.net/convert-address-to-lat-long.html



-- Query to find N nearest trees given a latitude and longitude
-- Using a CTE to define the location

transform a set of lat long to a geography type with 

```sql
SELECT ST_SetSRID(ST_MakePoint(-74.0060, 40.7128), 4326)::geography AS geog
```

so the query becomes 

```sql
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

# Transform the geo_point_2d from varchar to POINT


* We add a column ```geolocation``` with type POINT.
* Update the new column with POINT values  
* delete the original ```geo_point_2d``` column

```sql
ALTER TABLE trees ADD COLUMN geolocation POINT;

UPDATE trees
SET geolocation = point(
    TRIM(SPLIT_PART(geo_point_2d, ',', 2))::float,
    TRIM(SPLIT_PART(geo_point_2d, ',', 1))::float
);

ALTER TABLE trees DROP COLUMN geo_point_2d;
```

Note that the lat and longitude have been swapped.

We should verify that this makes sense (use google maps)



* In geo_point_2d (String representation):
    * The order is typically (latitude, longitude). This is a common human-readable format, often used in everyday applications and GPS coordinates. 
* In geolocation (Point data type):
    * The order is (x, y), which for geographic coordinates translates to (longitude, latitude). This is the standard for many geographic information systems and spatial databases. 
 

## Closest tree
Given a tree index, find the N closest trees



```sql

WITH given_tree AS (
  SELECT id, geolocation
  FROM trees
  WHERE id = 1234  
)
SELECT 
  t.id, 
  t.geolocation,
  ROUND(
    SQRT(
      POW((t.geolocation[0] - gt.geolocation[0]) * 73000, 2) +
      POW((t.geolocation[1] - gt.geolocation[1]) * 111000, 2)
    )
  ) AS distance_meters
FROM trees t, given_tree gt
WHERE t.id != gt.id
ORDER BY t.geolocation <-> gt.geolocation
LIMIT 9;
```


This query directly calculates the euclidian distance to find the distance between 2 points and applies different scales to latitude and longitude (111000 and 73000 respectively).


We can then adapt the query to find the trees near a given location if we know its coordinates

## Some common queries 

To finish our work on the trees table, we'd like to flag trees that have anomalies

So let's create a BOOLEAN column that indicates that there's an anomaly with a tree record.

```sql
alter table trees add column anomaly bool default FALSE NOT NULL;
```

Then find some weird trees

* find the trees that are too tall
* same thing for the circumference

to find anomalies in the circumference, you can convert the circumference to the diameter with 

```sql
select circumference / PI() as diameter from trees
```

You create a new diameter column with

```sql
alter table trees add column diameter float;
```

and update the diameter column with 
```sql
update trees 
set diameter = circumference / PI();
```

and find trees that have a insanely high diameter

update the anomaly column with these trees

also set the anomaly column to true for duplicates of idbase

are there other anomalies such as duplicates addresses or zero values for height or cicumference / diameter ?

To detect anomalies for a given column, you can get a good insight about a variable distribution by writing a query to find : min, max, average, median, 95 and 5 percentiles for a given float ccolumn. 
this mimics the ```df.describe()``` in pandas dataframes.

```sql
SELECT
    COUNT(diameter) AS count,
    AVG(diameter) AS mean,
    STDDEV(diameter) AS stddev,
    MIN(diameter) AS min,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY diameter) AS q05,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY diameter) AS q1,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY diameter) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY diameter) AS q3,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY diameter) AS q95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY diameter) AS q99,
    MAX(diameter) AS max
FROM trees;

```


It may be difficult to deciode if the height or diameter of a tree is an anomaly or not.

for instance the tree 187635 has a height of 98m. 

column | value 
--- | ---
idbase         | 2018097
location_type  | Arbre
domain         | Alignement
arrondissement | PARIS 18E ARRDT
suppl_address  | 108V
number         | 
address        | RUE DE LA CHAPELLE
id_location    | 2002004
name           | Platane
genre          | Platanus
species        | x hispanica
variety        | 
circumference  | 68
**height**         | **98**
stage          | Jeune (arbre)
geo_point_2d   | 48.89815810816667, 2.3591531336170086
id             | 187635
remarkable     | f
diameter       | 21.645072260497766
geolocation    | (2.3591531336170086,48.89815810816667)


that's a lot but is it a valid height for a  tree? Are they trees that tall in Paris ?

We can investigate in 2 ways 

input the coordinates in google maps and look at the [photo of the street](https://www.google.com/maps/@48.8982496,2.3591069,3a,75y,180h,90t/data=!3m7!1e1!3m5!1sWZpyESvb1Go6xQS5MH5JNg!2e0!6shttps:%2F%2Fstreetviewpixels-pa.googleapis.com%2Fv1%2Fthumbnail%3Fpanoid%3DWZpyESvb1Go6xQS5MH5JNg%26cb_client%3Dsearch.revgeo_and_fetch.gps%26w%3D96%26h%3D64%26yaw%3D50.489685%26pitch%3D0%26thumbfov%3D100!7i16384!8i8192!5m1!1e4?coh=205409&entry=ttu&g_ep=EgoyMDI0MDkwNC4wIKXMDSoASAFQAw%3D%3D)



or check the height of nearby trees with the closest trees query 

```sql
WITH given_tree AS (
  SELECT id, geolocation
  FROM trees
  WHERE id = 187635  
)
SELECT 
  t.id, 
  t.height,
  t.geolocation,
  ROUND(
    SQRT(
      POW((t.geolocation[0] - gt.geolocation[0]) * 73000, 2) +
      POW((t.geolocation[1] - gt.geolocation[1]) * 111000, 2)
    )
  ) AS distance_meters
FROM trees t, given_tree gt
--WHERE t.id != gt.id
ORDER BY t.geolocation <-> gt.geolocation
LIMIT 9;

```
All surrounding trees have a height of 5 to 16 meters. So 98 meters is not a valid measurement.



 
### Solution

the 100m threshold is arbitrary. For a real data analysis and we would have to find more relevant thresholds.

```sql
update trees set anomaly = TRUE where (diameter > 100) or (height > 100);
```

and to flag the trees with duplicate idabase
```sql
update trees set anomaly = true where  idbase IN (
    SELECT idbase
    FROM trees
    GROUP BY idbase
    HAVING COUNT(*) > 1
);
```
 
In the end we have 851 trees with anomaly measurements.

# Recap

The table loaded from the csv / sql dump was lacking a primary key, proper datatypes and had many data anomalies

* We checked that the ```idbase``` column was not a good choice as a primary key
* Transformed remarkable as a boolean data type, 
* installed and activated the postgis extension (when possible)
* which allowed us to transform the geo_point_2d into a postGIS GEOGRAPGY data type and find closest trees given a location
* we also looked at the native POINT data type
* We identified the extreme or missing values of height, circumference and diameter of some trees and flagged these trees. 


The current table is much more clean and in a state more compatible with production.

Next we move away from the single table database and start building a proper relational database from that dataset.


