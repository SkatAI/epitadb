# todo

0. set the server IP address

- get the IP address

```bash
gcloud compute instances describe epitadb-permanent --zone us-central1-c --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
# > 35.232.113.248
export PGHOST=35.232.113.248
```

or in one line

```bash
export PGHOST=$(gcloud compute instances describe epitadb-permanent --zone us-central1-c --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
```

Then check with

```bash
echo $PGHOST
```

1. init
start from empty treesdb_v01

```sql
\c postgres

drop  database  if exists treesdb_v01 with(force) ;

CREATE DATABASE treesdb_v01
    WITH
    OWNER = epita
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
```

on local restore 01.07.backup in pgAdmin

```bash
pg_restore  -d "treesdb_v01" \
-U alexis \
--section=pre-data \
--section=data \
--section=post-data \
--verbose \
--exit-on-error  \
"/Users/alexis/work/epitadb/data/treesdb_v01.07.sql.backup"
```


pg_dump local as 01.08.backup

```bash
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

```

drop and create  remote treedb_v01

pg_restore remote 01.08.backup on remote

```bash
pg_restore -h $PGHOST \
-d "treesdb_v01" \
-U epita \
-W \
--no-owner \
--no-privileges \
--no-data-for-failed-tables \
--section=pre-data \
--section=data \
--section=post-data \
--verbose \
--exit-on-error  \
"/Users/alexis/work/epitadb/data/treesdb_v01.08.sql.backup"
```

# check local and remote

on remote or local

3. sql to v02
start from empty treesdb_v01

    drop db treesdb_v01
    create db treesdb_v01

restore 01.08.backup into treesdb_v01

go through 01 to 02 sql scripts :  from_v01_to_v02.sql

pg dump  to 02.01.backup

4. sql to v03

empty treesdb_v02
pg_restore 02.01.backup into treesdb_v02

go through 02 to 03 sql scripts :  from_v02_to_v03.sql
pg dump to 03.01.backup