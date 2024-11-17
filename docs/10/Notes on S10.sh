# Notes on S10

# on windows: replace -U alexis with -U postgres

pg_dump \
    -h localhost  -U alexis \
    --no-owner \
    --no-acl \
    --clean \
    --if-exists \
    --format=custom \
    --compress=9 \
    --file=./data/ademe_backup_01.dump \
    ademedb


dropdb -h localhost -U alexis --if-exists ademedb

psql -h localhost -d postgres -c '\l'

createdb -h localhost -U alexis --encoding 'UTF8'  ademedb

pg_restore -h localhost -U alexis \
    --no-owner \
    --no-acl \
    --clean \
    --if-exists \
    --dbname=ademedb \
    ./data/ademe_backup_01.dump


psql -h localhost -d ademedb -c 'select count(*) from dpe;'

# labels

drop table if exists energy_labels;

CREATE TABLE energy_labels (
    grade CHAR(1) PRIMARY KEY,
    min_cons NUMERIC,
    max_cons NUMERIC,
    emission_min NUMERIC,
    emission_max NUMERIC
);

INSERT INTO energy_labels (grade, min_cons, max_cons, emission_min, emission_max) VALUES
('A', 0, 70, 0, 6),
('B', 71, 110, 7, 11),
('C', 111, 180, 12, 30),
('D', 181, 250, 31, 50),
('E', 251, 330, 51, 70),
('F', 331, 420, 71, 100),
('G', 421, NULL, 101, NULL);