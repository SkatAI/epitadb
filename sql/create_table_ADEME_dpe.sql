Drop table if exists dpe;

CREATE TABLE dpe (
    id SERIAL PRIMARY KEY,
    dpe_number TEXT,
    dpe_reception_date DATE,
    dpe_issue_date DATE,
    inspector_visit_date DATE,
    dpe_expiry_date DATE,
    dpe_method TEXT,
    dpe_label TEXT,
    ghg_label TEXT,
    energy_use_kwhepm2year NUMERIC,
    ghg_emissions_kgco2m2year NUMERIC,
    construction_year NUMERIC,
    erp_category TEXT,
    construction_period TEXT,
    activity_sector TEXT,
    occupant_count NUMERIC,
    gross_floor_area NUMERIC,
    usable_area NUMERIC,
    main_heating_energy_type TEXT,
    city_name_ban TEXT,
    insee_code_ban TEXT,
    street_number_ban TEXT,
    ban_id TEXT,
    address_ban TEXT,
    postal_code_ban NUMERIC,
    ban_score NUMERIC,
    street_name_ban TEXT,
    x_coordinate_ban NUMERIC,
    y_coordinate_ban NUMERIC,
    apartment_floor NUMERIC,
    residence_name TEXT,
    building_address_details TEXT,
    housing_address_details TEXT,
    geocoding_status TEXT,
    department_number_ban TEXT,
    region_number_ban NUMERIC,
    final_energy_use_01 NUMERIC,
    primary_energy_use_01 NUMERIC,
    energy_type_01 TEXT,
    energy_usage_type_01 TEXT,
    annual_energy_cost_01 NUMERIC,
    energy_reading_year_01 NUMERIC,
    final_energy_use_02 NUMERIC,
    primary_energy_use_02 NUMERIC,
    energy_type_02 TEXT,
    energy_usage_type_02 TEXT,
    annual_energy_cost_02 NUMERIC,
    energy_reading_year_02 NUMERIC,
    final_energy_use_03 NUMERIC,
    primary_energy_use_03 NUMERIC,
    energy_type_03 TEXT,
    energy_usage_type_03 TEXT,
    annual_energy_cost_03 NUMERIC,
    energy_reading_year_03 NUMERIC
);

ALTER TABLE dpe ALTER COLUMN construction_year TYPE INTEGER USING (ROUND(construction_year)::INTEGER);
ALTER TABLE dpe ALTER COLUMN occupant_count TYPE INTEGER USING (ROUND(occupant_count)::INTEGER);
ALTER TABLE dpe ALTER COLUMN postal_code_ban TYPE INTEGER USING (ROUND(postal_code_ban)::INTEGER);
ALTER TABLE dpe ALTER COLUMN apartment_floor TYPE INTEGER USING (ROUND(apartment_floor)::INTEGER);
ALTER TABLE dpe ALTER COLUMN region_number_ban TYPE INTEGER USING (ROUND(region_number_ban)::INTEGER);

-- rename

ALTER TABLE dpe RENAME COLUMN final_energy_use_01 TO final_energy_cons_01;
ALTER TABLE dpe RENAME COLUMN final_energy_use_02 TO final_energy_cons_02;
ALTER TABLE dpe RENAME COLUMN final_energy_use_03 TO final_energy_cons_03;

ALTER TABLE dpe RENAME COLUMN primary_energy_use_01 TO primary_energy_cons_01;
ALTER TABLE dpe RENAME COLUMN primary_energy_use_02 TO primary_energy_cons_02;
ALTER TABLE dpe RENAME COLUMN primary_energy_use_03 TO primary_energy_cons_03;
