# db4 database creation

## 1. dump db3 (1000 tree subset)

no need

## 2. create db4

If on Mac replace `OWNER = postgres` with `OWNER = your local username`

```sql
DROP database if exists treesdb_v04 WITH(force) ;

CREATE DATABASE treesdb_v04
    WITH
    OWNER = alexis
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
```

## 3. restore db3 into db4

-- load treesdb_v03.01.sql.backup into treesdb_v04

```bash
pg_restore -h localhost \
-d treesdb_v04 \
-U alexis \
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

```

## 4. rename tables in db4

### rename tables

 public | tree_domains   | table | alexis
 public | tree_genres    | table | alexis
 public | tree_names     | table | alexis
 public | tree_species   | table | alexis
 public | tree_stages    | table | alexis
 public | tree_varieties | table | alexis

```sql
SELECT
    tc.table_schema AS referencing_schema,
    tc.table_name AS referencing_table,
    kcu.column_name AS referencing_column,
    ccu.table_schema AS referenced_schema,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name AS constraint_name
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE
    tc.constraint_type = 'FOREIGN KEY'
    AND ccu.table_name = 'tree_domains'
ORDER BY
    tc.table_schema,
    tc.table_name;
```

```sql
ALTER TABLE table_name
RENAME TO new_table_name;
```

### remove samples

subset of trees

```sql
alter table trees
add column keep boolean default False;


update trees set keep = FALSE;


with tree_selection as (
    select t.id from trees t
    join tree_domains td on td.id = t.domain_id
    join locations loc on loc.id = t.location_id
    where domain = 'Alignement'
    and arrondissement like 'PARIS%'
    and t.taxonomy_id is not null
    and height > 0
    and height is not null
    and stage_id is  not null
    order by random()
    limit 1000

)
UPDATE trees
SET keep = TRUE
WHERE id IN (SELECT id FROM tree_selection);


select * from trees t
join locations loc on loc.id = t.location_id
where t.keep;

```

```sql

delete from trees where not keep;

delete from taxonomy
where id not in (
    select taxonomy_id from trees where keep
);

```

```sql

DO $$
DECLARE
    batch_size INT := 5000; -- adjust as needed
    deleted INT;
BEGIN
    LOOP
        WITH to_delete AS (
            SELECT l.id
            FROM locations l
            WHERE NOT EXISTS (
                SELECT 1
                FROM trees t
                WHERE t.location_id = l.id
                AND t.keep = TRUE
            )
            LIMIT batch_size
        )
        DELETE FROM locations
        WHERE id IN (SELECT id FROM to_delete);

        GET DIAGNOSTICS deleted = ROW_COUNT;

        EXIT WHEN deleted = 0;

        COMMIT;
        RAISE NOTICE 'Deleted % rows', deleted;
    END LOOP;
END $$;

```

```sql
ANALYZE locations;
ANALYZE trees;


alter table trees drop column keep;
alter table locations drop column keep;
```

## 5. dump db 4 with no owner but with database

```bash
pg_dump -h localhost  \
  --no-owner \
  --format=plain \
  --exclude-schema='information_schema' \
  --exclude-schema='pg_*' \
  --section=pre-data \
  --section=data \
  --section=post-data \
  --no-privileges \
  --no-security-labels \
  --no-tablespaces \
  --no-unlogged-table-data \
  --no-publications \
  --no-subscriptions \
  --no-toast-compression \
  --no-comments \
  treesdb_v04 > treesdb_v04.01.sql
```

## 6. test restore db4

```sql
-- DROP database if exists treesdb_v04 WITH(force) ;
```

Create database treesdb_v04

then in psql

```sql
\i <absolutepath_to>/../treesdb_v04.01.sql
```

```bash
pg_restore \
  --no-owner \
  --no-privileges \
  --no-comments \
  --no-tablespaces \
  --format=plain \
  --dbname=treesdb_v04 \
  --clean \
  --create \
  treesdb_v04.01.sql
```
