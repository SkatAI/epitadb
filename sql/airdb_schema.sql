BEGIN;


CREATE TABLE IF NOT EXISTS postgres_air.account
(
    account_id serial NOT NULL,
    login text COLLATE pg_catalog."default" NOT NULL,
    first_name text COLLATE pg_catalog."default" NOT NULL,
    last_name text COLLATE pg_catalog."default" NOT NULL,
    frequent_flyer_id integer,
    update_ts timestamp with time zone,
    CONSTRAINT account_pkey PRIMARY KEY (account_id)
);

CREATE TABLE IF NOT EXISTS postgres_air.aircraft
(
    model text COLLATE pg_catalog."default",
    range numeric NOT NULL,
    class integer NOT NULL,
    velocity numeric NOT NULL,
    code text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT aircraft_pkey PRIMARY KEY (code)
);

CREATE TABLE IF NOT EXISTS postgres_air.airport
(
    airport_code character(3) COLLATE pg_catalog."default" NOT NULL,
    airport_name text COLLATE pg_catalog."default" NOT NULL,
    city text COLLATE pg_catalog."default" NOT NULL,
    airport_tz text COLLATE pg_catalog."default" NOT NULL,
    continent text COLLATE pg_catalog."default",
    iso_country text COLLATE pg_catalog."default",
    iso_region text COLLATE pg_catalog."default",
    intnl boolean NOT NULL,
    update_ts timestamp with time zone,
    CONSTRAINT airport_pkey PRIMARY KEY (airport_code)
);

CREATE TABLE IF NOT EXISTS postgres_air.boarding_pass
(
    pass_id serial NOT NULL,
    passenger_id bigint,
    booking_leg_id bigint,
    seat text COLLATE pg_catalog."default",
    boarding_time timestamp with time zone,
    precheck boolean,
    update_ts timestamp with time zone,
    CONSTRAINT boarding_pass_pkey PRIMARY KEY (pass_id)
);

CREATE TABLE IF NOT EXISTS postgres_air.booking
(
    booking_id bigint NOT NULL,
    booking_ref text COLLATE pg_catalog."default" NOT NULL,
    booking_name text COLLATE pg_catalog."default",
    account_id integer,
    email text COLLATE pg_catalog."default" NOT NULL,
    phone text COLLATE pg_catalog."default" NOT NULL,
    update_ts timestamp with time zone,
    price numeric(7, 2),
    CONSTRAINT booking_pkey PRIMARY KEY (booking_id),
    CONSTRAINT booking_booking_ref_key UNIQUE (booking_ref)
);

CREATE TABLE IF NOT EXISTS postgres_air.booking_leg
(
    booking_leg_id serial NOT NULL,
    booking_id integer NOT NULL,
    flight_id integer NOT NULL,
    leg_num integer,
    is_returning boolean,
    update_ts timestamp with time zone,
    CONSTRAINT booking_leg_pkey PRIMARY KEY (booking_leg_id)
);

CREATE TABLE IF NOT EXISTS postgres_air.flight
(
    flight_id serial NOT NULL,
    flight_no text COLLATE pg_catalog."default" NOT NULL,
    scheduled_departure timestamp with time zone NOT NULL,
    scheduled_arrival timestamp with time zone NOT NULL,
    departure_airport character(3) COLLATE pg_catalog."default" NOT NULL,
    arrival_airport character(3) COLLATE pg_catalog."default" NOT NULL,
    status text COLLATE pg_catalog."default" NOT NULL,
    aircraft_code character(3) COLLATE pg_catalog."default" NOT NULL,
    actual_departure timestamp with time zone,
    actual_arrival timestamp with time zone,
    update_ts timestamp with time zone,
    CONSTRAINT flight_pkey PRIMARY KEY (flight_id)
);

CREATE TABLE IF NOT EXISTS postgres_air.frequent_flyer
(
    frequent_flyer_id serial NOT NULL,
    first_name text COLLATE pg_catalog."default" NOT NULL,
    last_name text COLLATE pg_catalog."default" NOT NULL,
    title text COLLATE pg_catalog."default" NOT NULL,
    card_num text COLLATE pg_catalog."default" NOT NULL,
    level integer NOT NULL,
    award_points integer NOT NULL,
    email text COLLATE pg_catalog."default" NOT NULL,
    phone text COLLATE pg_catalog."default" NOT NULL,
    update_ts timestamp with time zone,
    CONSTRAINT frequent_flyer_pkey PRIMARY KEY (frequent_flyer_id)
);

CREATE TABLE IF NOT EXISTS postgres_air.passenger
(
    passenger_id serial NOT NULL,
    booking_id integer NOT NULL,
    booking_ref text COLLATE pg_catalog."default",
    passenger_no integer,
    first_name text COLLATE pg_catalog."default" NOT NULL,
    last_name text COLLATE pg_catalog."default" NOT NULL,
    account_id integer,
    update_ts timestamp with time zone,
    age integer,
    CONSTRAINT passenger_pkey PRIMARY KEY (passenger_id)
);

CREATE TABLE IF NOT EXISTS postgres_air.phone
(
    phone_id serial NOT NULL,
    account_id integer,
    phone text COLLATE pg_catalog."default",
    phone_type text COLLATE pg_catalog."default",
    primary_phone boolean,
    update_ts timestamp with time zone,
    CONSTRAINT phone_pkey PRIMARY KEY (phone_id)
);

ALTER TABLE IF EXISTS postgres_air.account
    ADD CONSTRAINT frequent_flyer_id_fk FOREIGN KEY (frequent_flyer_id)
    REFERENCES postgres_air.frequent_flyer (frequent_flyer_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.boarding_pass
    ADD CONSTRAINT booking_leg_id_fk FOREIGN KEY (booking_leg_id)
    REFERENCES postgres_air.booking_leg (booking_leg_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.boarding_pass
    ADD CONSTRAINT passenger_id_fk FOREIGN KEY (passenger_id)
    REFERENCES postgres_air.passenger (passenger_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.booking
    ADD CONSTRAINT booking_account_id_fk FOREIGN KEY (account_id)
    REFERENCES postgres_air.account (account_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.booking_leg
    ADD CONSTRAINT booking_id_fk FOREIGN KEY (booking_id)
    REFERENCES postgres_air.booking (booking_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
CREATE INDEX IF NOT EXISTS booking_leg_booking_id
    ON postgres_air.booking_leg(booking_id);


ALTER TABLE IF EXISTS postgres_air.booking_leg
    ADD CONSTRAINT flight_id_fk FOREIGN KEY (flight_id)
    REFERENCES postgres_air.flight (flight_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.flight
    ADD CONSTRAINT aircraft_code_fk FOREIGN KEY (aircraft_code)
    REFERENCES postgres_air.aircraft (code) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.flight
    ADD CONSTRAINT arrival_airport_fk FOREIGN KEY (arrival_airport)
    REFERENCES postgres_air.airport (airport_code) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.flight
    ADD CONSTRAINT departure_airport_fk FOREIGN KEY (departure_airport)
    REFERENCES postgres_air.airport (airport_code) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
CREATE INDEX IF NOT EXISTS flight_departure_airport
    ON postgres_air.flight(departure_airport);


ALTER TABLE IF EXISTS postgres_air.passenger
    ADD CONSTRAINT pass_account_id_fk FOREIGN KEY (account_id)
    REFERENCES postgres_air.account (account_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.passenger
    ADD CONSTRAINT pass_booking_id_fk FOREIGN KEY (booking_id)
    REFERENCES postgres_air.booking (booking_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.passenger
    ADD CONSTRAINT pass_frequent_flyer_id_fk FOREIGN KEY (account_id)
    REFERENCES postgres_air.account (account_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS postgres_air.phone
    ADD CONSTRAINT phone_account_id_fk FOREIGN KEY (account_id)
    REFERENCES postgres_air.account (account_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

END;