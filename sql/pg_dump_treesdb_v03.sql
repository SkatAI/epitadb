--
-- treesdb_v03 PostgreSQL database dump
--

CREATE TABLE public.trees (
    idbase integer,
    id_location_legacy character varying,
    circumference integer,
    height integer,
    id integer NOT NULL,
    remarkable boolean,
    diameter double precision,
    domain_id integer,
    stage_id integer,
    taxonomy_id integer,
    location_id integer
);

CREATE TABLE public.locations (
    id integer NOT NULL,
    suppl_address character varying,
    address character varying,
    arrondissement character varying,
    geolocation character varying
);

CREATE TABLE public.taxonomy (
    id integer NOT NULL,
    name_id integer,
    genre_id integer,
    species_id integer,
    variety_id integer
);


CREATE TABLE public.tree_genres (
    id integer NOT NULL,
    genre character varying(255) NOT NULL
);


CREATE TABLE public.tree_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


CREATE TABLE public.tree_species (
    id integer NOT NULL,
    species character varying(255) NOT NULL
);

CREATE TABLE public.tree_varieties (
    id integer NOT NULL,
    variety character varying(255) NOT NULL
);

CREATE TABLE public.tree_domains (
    id integer NOT NULL,
    domain character varying
);

CREATE TABLE public.tree_stages (
    id integer NOT NULL,
    stage character varying
);

