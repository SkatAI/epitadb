""
dataset from https://www.kaggle.com/datasets/thebumpkin/300-world-music-tracks-with-spotify-data
""

-- psql into your local server
--

-- create a new database,
CREATE DATABASE worldhitsdb
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- connect to worldhits
\c worldhits

-- create the main table
CREATE TABLE tracks (
    Track VARCHAR(255),
    Artist VARCHAR(255),
    Album VARCHAR(255),
    Year INT,
    Duration INT,
    Time_Signature INT,
    Danceability FLOAT,
    Energy FLOAT,
    Key INT,
    Loudness FLOAT,
    Mode INT,
    Speechiness FLOAT,
    Acousticness FLOAT,
    Instrumentalness FLOAT,
    Liveness FLOAT,
    Valence FLOAT,
    Tempo FLOAT,
    Popularity INT
);

-- copy the data into the table
-- change the path to WorldHits.csv
\COPY tracks FROM '/Users/alexis/work/epitadb/data/WorldHits.csv' WITH CSV HEADER DELIMITER ',';

-- run the query
select count(*) from tacks;

-- should return N rows