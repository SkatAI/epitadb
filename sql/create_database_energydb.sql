CREATE DATABASE energydb
    WITH
    OWNER = alexis
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


-- Create tables
CREATE TABLE energy_sources (
    id SERIAL PRIMARY KEY,
    source_name VARCHAR(50) NOT NULL
);

CREATE TABLE countries (
    id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL
);

CREATE TABLE production_entities (
    id SERIAL PRIMARY KEY,
    entity_name VARCHAR(100) NOT NULL,
    energy_source_id INTEGER REFERENCES energy_sources(id),
    country_id INTEGER REFERENCES countries(id),
    capacity_mw NUMERIC(10, 2) NOT NULL,
    built_date DATE NOT NULL,
    lifespan_years INTEGER NOT NULL,
    end_of_life_date DATE NOT NULL,
    last_maintenance_date DATE,
    total_energy_produced_mwh NUMERIC(15, 2) NOT NULL,
    carbon_emissions_tons NUMERIC(10, 2),
    other_emissions_tons NUMERIC(10, 2),
    initial_cost_usd NUMERIC(15, 2) NOT NULL,
    roi_percent NUMERIC(5, 2) NOT NULL
);

-- Insert data into energy_sources
INSERT INTO energy_sources (source_name) VALUES
('Solar'), ('Wind'), ('Geothermal'), ('Coal'), ('Natural Gas'), ('Nuclear');

-- Insert data into countries
INSERT INTO countries (country_name) VALUES
('United States'), ('China'), ('Germany'), ('India'), ('Japan'),
('United Kingdom'), ('France'), ('Italy'), ('Canada'), ('Australia');

-- Function to generate random dates
CREATE OR REPLACE FUNCTION random_date(start_date DATE, end_date DATE)
RETURNS DATE AS $$
BEGIN
    RETURN start_date + (random() * (end_date - start_date))::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Function to generate production entities data
CREATE OR REPLACE FUNCTION generate_production_entities(num_rows INTEGER)
RETURNS VOID AS $$
DECLARE
    i INTEGER;
    v_energy_source_id INTEGER;
    v_country_id INTEGER;
    v_capacity_mw NUMERIC(10, 2);
    v_built_date DATE;
    v_lifespan_years INTEGER;
    v_end_of_life_date DATE;
    v_last_maintenance_date DATE;
    v_total_energy_produced_mwh NUMERIC(15, 2);
    v_carbon_emissions_tons NUMERIC(10, 2);
    v_other_emissions_tons NUMERIC(10, 2);
    v_initial_cost_usd NUMERIC(15, 2);
    v_roi_percent NUMERIC(5, 2);
BEGIN
    FOR i IN 1..num_rows LOOP
        -- Generate random values for each column
        v_energy_source_id := floor(random() * 6 + 1);
        v_country_id := floor(random() * 10 + 1);
        v_capacity_mw := random() * 1000;
        v_built_date := random_date('2000-01-01', '2023-12-31');
        v_lifespan_years := floor(random() * 30 + 10);
        v_end_of_life_date := v_built_date + (v_lifespan_years || ' years')::INTERVAL;
        v_last_maintenance_date := random_date(v_built_date, LEAST(v_end_of_life_date, CURRENT_DATE));
        v_total_energy_produced_mwh := v_capacity_mw * 24 * 365 * (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM v_built_date)) * random();
        v_carbon_emissions_tons := CASE WHEN v_energy_source_id IN (4, 5) THEN v_total_energy_produced_mwh * random() * 0.1 ELSE 0 END;
        v_other_emissions_tons := CASE WHEN v_energy_source_id IN (4, 5, 6) THEN v_total_energy_produced_mwh * random() * 0.01 ELSE 0 END;
        v_initial_cost_usd := v_capacity_mw * (CASE v_energy_source_id
                                               WHEN 1 THEN 1000000
                                               WHEN 2 THEN 1500000
                                               WHEN 3 THEN 2000000
                                               WHEN 4 THEN 3000000
                                               WHEN 5 THEN 1000000
                                               WHEN 6 THEN 6000000
                                               END) * random();
        v_roi_percent := random() * 20;

        -- Insert the generated data
        INSERT INTO production_entities (
            entity_name, energy_source_id, country_id, capacity_mw, built_date, lifespan_years,
            end_of_life_date, last_maintenance_date, total_energy_produced_mwh, carbon_emissions_tons,
            other_emissions_tons, initial_cost_usd, roi_percent
        ) VALUES (
            'Entity_' || i, v_energy_source_id, v_country_id, v_capacity_mw, v_built_date, v_lifespan_years,
            v_end_of_life_date, v_last_maintenance_date, v_total_energy_produced_mwh, v_carbon_emissions_tons,
            v_other_emissions_tons, v_initial_cost_usd, v_roi_percent
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;


--- add energy_production_daily

CREATE TABLE energy_production_daily (
    id SERIAL PRIMARY KEY,
    production_entity_id INTEGER REFERENCES production_entities(id),
    date DATE NOT NULL,
    energy_produced_mwh NUMERIC(10, 2) NOT NULL
);

-- Function to generate daily energy production data
CREATE OR REPLACE FUNCTION public.generate_daily_production(num_days integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_batch_size INTEGER := 2000; -- Adjust this value based on your system's memory
    v_batches INTEGER := CEIL(num_days::float / v_batch_size);
    v_entity_ids INTEGER[];
    v_entity_capacities NUMERIC[];
    v_max_id INTEGER;
    v_min_id INTEGER;
BEGIN
    -- Get the range of production entity IDs
    SELECT MIN(id), MAX(id) INTO v_min_id, v_max_id FROM production_entities;

    -- Precompute random entity IDs and their capacities
    WITH random_entities AS (
        SELECT id, capacity_mw
        FROM production_entities
        WHERE id IN (
            SELECT (random() * (v_max_id - v_min_id) + v_min_id)::integer
            FROM generate_series(1, LEAST(num_days, v_max_id - v_min_id))
        )
    )
    SELECT array_agg(id), array_agg(capacity_mw)
    INTO v_entity_ids, v_entity_capacities
    FROM random_entities;

    -- Generate and insert data in batches
    FOR i IN 1..v_batches LOOP
        INSERT INTO energy_production_daily (production_entity_id, date, energy_produced_mwh)
        SELECT
            v_entity_ids[1 + ((gs.id - 1) % array_length(v_entity_ids, 1))],
            CURRENT_DATE - (random() * 365)::INTEGER,
            random() * v_entity_capacities[1 + ((gs.id - 1) % array_length(v_entity_capacities, 1))] * 24
        FROM generate_series(1, LEAST(v_batch_size, num_days - (i-1)*v_batch_size)) gs(id);
    END LOOP;
END;
$function$;


-- Generate 1 million rows
SELECT generate_production_entities(1000000);

-- Generate 5 million rows of daily production data
SELECT generate_daily_production(500000);
