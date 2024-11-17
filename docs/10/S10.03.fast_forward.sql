CREATE TABLE energy_use (
    id serial PRIMARY KEY,
    dpe_id integer REFERENCES dpe(id),
    priority smallint CHECK (priority IN (1, 2, 3)),
    type text,
    usage text,
    cost numeric,
    reading_year numeric,

    UNIQUE (dpe_id, priority)
);

-- Insert data using CTE
WITH energy_data AS (
    -- Priority 1 records
    SELECT
        id as dpe_id,
        1 as priority,
        energy_type_01 as type,
        energy_usage_type_01 as usage,
        annual_energy_cost_01 as cost,
        energy_reading_year_01 as reading_year
    FROM dpe
    WHERE energy_type_01 IS NOT NULL
       OR energy_usage_type_01 IS NOT NULL
       OR annual_energy_cost_01 >0
       OR energy_reading_year_01 >0

    UNION ALL

    -- Priority 2 records
    SELECT
        id as dpe_id,
        2 as priority,
        energy_type_02,
        energy_usage_type_02,
        annual_energy_cost_02,
        energy_reading_year_02
    FROM dpe
    WHERE energy_type_02 IS NOT NULL
       OR energy_usage_type_02 IS NOT NULL
       OR annual_energy_cost_02 >0
       OR energy_reading_year_02 >0

    UNION ALL

    -- Priority 3 records
    SELECT
        id as dpe_id,
        3 as priority,
        energy_type_03,
        energy_usage_type_03,
        annual_energy_cost_03,
        energy_reading_year_03
    FROM dpe
    WHERE energy_type_03 IS NOT NULL
       OR energy_usage_type_02 IS NOT NULL
       OR annual_energy_cost_03 >0
       OR energy_reading_year_03 >0
)
INSERT INTO energy_use (
    dpe_id,
    priority,
    type,
    usage,
    cost,
    reading_year
)
SELECT * FROM energy_data;


### ban

-- First create the ban table
CREATE TABLE ban (
    id serial PRIMARY KEY,
    dpe_id integer REFERENCES dpe(id) UNIQUE,  -- one-to-one relationship
    city_name text,
    insee_code text,
    street_number text,
    ban_id text,
    address text,
    postal_code integer,
    score numeric,
    street_name text,
    x_coordinate numeric,
    y_coordinate numeric,
    department_number text,
    region_number integer
);

-- Create an index for the foreign key
CREATE INDEX idx_ban_dpe_id ON ban(dpe_id);

-- Insert data from dpe table
INSERT INTO ban (
    dpe_id,
    city_name,
    insee_code,
    street_number,
    ban_id,
    address,
    postal_code,
    score,
    street_name,
    x_coordinate,
    y_coordinate,
    department_number,
    region_number
)
SELECT
    id,
    city_name_ban,
    insee_code_ban,
    street_number_ban,
    ban_id,
    address_ban,
    postal_code_ban,
    ban_score,
    street_name_ban,
    x_coordinate_ban,
    y_coordinate_ban,
    department_number_ban,
    region_number_ban
FROM dpe;

-- Drop the columns from dpe table

ALTER TABLE dpe
    DROP COLUMN energy_type_01,
    DROP COLUMN energy_usage_type_01,
    DROP COLUMN annual_energy_cost_01,
    DROP COLUMN energy_reading_year_01,
    DROP COLUMN energy_type_02,
    DROP COLUMN energy_usage_type_02,
    DROP COLUMN annual_energy_cost_02,
    DROP COLUMN energy_reading_year_02,
    DROP COLUMN energy_type_03,
    DROP COLUMN energy_usage_type_03,
    DROP COLUMN annual_energy_cost_03,
    DROP COLUMN energy_reading_year_03,
    DROP COLUMN city_name_ban,
    DROP COLUMN insee_code_ban,
    DROP COLUMN street_number_ban,
    DROP COLUMN ban_id,
    DROP COLUMN address_ban,
    DROP COLUMN postal_code_ban,
    DROP COLUMN ban_score,
    DROP COLUMN street_name_ban,
    DROP COLUMN x_coordinate_ban,
    DROP COLUMN y_coordinate_ban,
    DROP COLUMN department_number_ban,
    DROP COLUMN region_number_ban;
