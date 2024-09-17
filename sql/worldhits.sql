""
dataset from https://www.kaggle.com/datasets/thebumpkin/300-world-music-tracks-with-spotify-data


""
CREATE DATABASE worldhits
    WITH
    OWNER = alexis
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

\c worldhits
-- create the table
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


\COPY tracks FROM '/Users/alexis/work/epitadb/data/WorldHits.csv' WITH CSV HEADER DELIMITER ',';

