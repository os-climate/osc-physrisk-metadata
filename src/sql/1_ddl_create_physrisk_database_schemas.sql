-- PHYRISK EXAMPLE DATABASE STRUCTURE
-- Intended to help standardize glossary/metadata as well as field core_names and constraints
-- to align with phys-risk/geo-indexer/other related initiatives and 
-- speed up application development, help internationalize and display the results of analyses, and more.
-- The backend schema User and Tenant tables are derived from ASP.NET Boilerplate tables (https://aspnetboilerplate.com/). That code is available under the MIT license, here: https://github.com/aspnetboilerplate/aspnetboilerplate

-- SETUP EXTENSIONS
CREATE EXTENSION IF NOT EXISTS postgis; -- used for geolocation
CREATE EXTENSION IF NOT EXISTS h3; -- used for Uber H3 geolocation
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- used for random UUID generation

-- SETUP SCHEMAS
CREATE SCHEMA IF NOT EXISTS osc_physrisk_backend;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_org;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_model;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_assets;
CREATE SCHEMA IF NOT EXISTS osc_physrisk_analysis;

-- SETUP TABLES
-- SCHEMA osc_physrisk_backend

CREATE TABLE osc_physrisk_backend.user (
	core_id bigint NOT NULL,
	core_temporal_datetime_utc_created       timestamptz  NOT NULL  ,
	core_user_creator_id      bigint    ,
	core_temporal_datetime_utc_last_modified timestamptz    ,
	core_user_last_modifier_id bigint    ,
	core_is_deleted          boolean  NOT NULL  ,
	core_user_deleter_id      bigint    ,
	core_temporal_datetime_utc_deleted       timestamptz    ,
	core_user_name VARCHAR(255) NOT NULL,
	core_tenant_id INTEGER,
	email_address VARCHAR(255) NOT NULL,
	core_name        VARCHAR(255)  NOT NULL  ,
	core_surname        VARCHAR(255)  NOT NULL  ,
	core_is_active       boolean  NOT NULL  ,
	PRIMARY KEY (core_id)
);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (core_user_creator_id) 
	REFERENCES osc_physrisk_backend.user (core_id);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (core_user_deleter_id) 
	REFERENCES osc_physrisk_backend.user (core_id);

ALTER TABLE osc_physrisk_backend.user
	ADD FOREIGN KEY (core_user_last_modifier_id) 
	REFERENCES osc_physrisk_backend.user (core_id);

CREATE INDEX "ix_osc_physrisk_backend_users_core_user_creator_id" ON osc_physrisk_backend.user USING btree (core_user_creator_id);
CREATE INDEX "ix_osc_physrisk_backend_users_core_user_deleter_id" ON osc_physrisk_backend.user USING btree (core_user_deleter_id);
CREATE INDEX "ix_osc_physrisk_backend_users_core_user_last_modifier_id" ON osc_physrisk_backend.user USING btree (core_user_last_modifier_id);
CREATE INDEX "ix_osc_physrisk_backend_users_email_address" ON osc_physrisk_backend.user USING btree (core_tenant_id, email_address);
CREATE INDEX "ix_osc_physrisk_backend_users_core_tenant_id_core_user_name" ON osc_physrisk_backend.user USING btree (core_tenant_id, core_user_name);

COMMENT ON TABLE osc_physrisk_backend.user IS 'Stores user information.';

CREATE TABLE osc_physrisk_backend.tenant (
	core_id bigint NOT NULL,
	core_temporal_datetime_utc_created       timestamptz  NOT NULL  ,
	core_user_creator_id      bigint    ,
	core_temporal_datetime_utc_last_modified timestamptz    ,
	core_user_last_modifier_id bigint    ,
	core_is_deleted          boolean  NOT NULL  ,
	core_user_deleter_id      bigint    ,
	core_temporal_datetime_utc_deleted       timestamptz    ,
	core_name varchar(64) NOT NULL,
	core_tenancy_name VARCHAR(255) NOT NULL,
	core_is_active       boolean  NOT NULL  ,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_tenants_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_tenants_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_tenants_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id)
);

CREATE INDEX "ix_osc_physrisk_backend_tenants_core_temporal_datetime_utc_created" ON osc_physrisk_backend.tenant USING btree (core_temporal_datetime_utc_created);
CREATE INDEX "ix_osc_physrisk_backend_tnants_core_user_creator_id" ON osc_physrisk_backend.tenant USING btree (core_user_creator_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_core_user_deleter_id" ON osc_physrisk_backend.tenant USING btree (core_user_deleter_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_core_user_last_modifier_id" ON osc_physrisk_backend.tenant USING btree (core_user_last_modifier_id);
CREATE INDEX "ix_osc_physrisk_backend_tenants_core_tenancy_name" ON osc_physrisk_backend.tenant USING btree (core_tenancy_name);

COMMENT ON TABLE osc_physrisk_backend.tenant IS 'Stores tenant information to support multi-tenancy data (where appropriate). A default tenant is always provcore_ided.';

CREATE TABLE osc_physrisk_backend.data_set ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_version TEXT DEFAULT '1.0',
	data_contact TEXT NOT NULL, -- Contact information for inquiries about the dataset.
	data_quality TEXT NOT NULL, -- Information on the accuracy, completeness, and source of the data.
	data_format TEXT NOT NULL, -- Formats in which the data is available.
	data_schema TEXT NOT NULL, -- Describe the data schema, or reference the Json Schema or Frictionless CSV schema. Can be a hyperlink to a relevant schema file.
	data_access_rights TEXT NOT NULL, -- Information on who can access the dataset.
	data_usage_notes TEXT NOT NULL, -- Notes on how the dataset can be used.
	data_related TEXT NOT NULL, -- Links to related datasets for further information or analysis. Could be a list of UUIDs or a textual description, or hyperlinks
	license_name_prefix varchar(12),
	license_name_suffix varchar(12),
	license_name_full varchar(255),
	license_name_short varchar(50),
	license_description_full varchar(8096),
	license_description_short varchar(255),
	license_text text,
	license_standard_license_header varchar(255),
	license_full_terms_url varchar(255),
	CONSTRAINT pk_scenario PRIMARY KEY ( core_id ),
	CONSTRAINT fk_scenario_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_scenario_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_scenario_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id)
 ); 

 COMMENT ON TABLE osc_physrisk_backend.data_set IS 'Contains a list of the data sets that are in use in this database, facilitating rigourous data hygeine, governance, and reporting tasks.';


CREATE TABLE osc_physrisk_backend.country ( 
	core_id UUID  DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	continent text NOT NULL,
	united_nations_global_code NUMERIC NOT NULL, -- Numeric but zero padded
	united_nations_global_name VARCHAR(255) NOT NULL,
	united_nations_region_code NUMERIC NOT NULL, -- Numeric but zero padded
	united_nations_region_name VARCHAR(255) NOT NULL,
	united_nations_sub_region_code NUMERIC, -- Numeric but zero padded
	united_nations_sub_region_name VARCHAR(255),
	united_nations_intermediate_region_code NUMERIC, -- Numeric but zero padded
	united_nations_intermediate_region_name VARCHAR(255),
	united_nations_code_m49 NUMERIC NOT NULL, -- Numeric but zero padded
	united_nations_is_ldc BOOLEAN, -- True if listed on UN Least Developed Countries (LDC)
	united_nations_is_lldc BOOLEAN, -- True if listed on Land Locked Developing Countries (LLDC)
	united_nations_is_sids BOOLEAN, -- True if listed on Small Island Developing States (SIDS)
	iso_code_alpha2 CHAR(2) NOT NULL, -- Alpha-2
	iso_code_alpha3 CHAR(3) NOT NULL, -- Alpha-3
	core_spatial_geometry geometry,
	core_spatial_bbox _float8,
	CONSTRAINT pk_country PRIMARY KEY ( core_id ),
	CONSTRAINT fk_country_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_country_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_country_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_country_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)
); 

 COMMENT ON TABLE osc_physrisk_backend.country IS 'Contains a list of country ISO codes as described in ISO 3166 standard.';

-- SCHEMA osc_physrisk_org
CREATE TABLE osc_physrisk_org.industry (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	standard_level smallint NOT NULL,
	standard_structure integer NOT NULL,
	standard_superscript text NOT NULL,
	standard_id uuid NOT NULL,
	standard_code text NOT NULL,
	parent_standard_code text,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_industry_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_industry_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_industry_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_industry_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)
	
);

CREATE TABLE osc_physrisk_org.organization (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	industry_gics text,
	industry_icb text,
	industry_nace text,
	industry_naics text,
	industry_naics_parent text,
	industry_sic text,
	id_bloomberg_id varchar(12),
	id_bloomberg_ticker varchar(12),
	id_duns text,
	id_figi text,
	id_fitch text,
	id_isin text,
	id_lei varchar(20),
	id_moodys text,
	id_national_company text,
	id_national_tax text,
	id_sp text,
	headquarters_address text NOT NULL,
	offices _text NOT NULL,
	parent_name text NOT NULL,
	schemadotorg jsonb NOT NULL,
	contact_name varchar(255),
	contact_type text,
	contact_email _text,
	contact_fax text,
	contact_telephone _text,
	contact_available_languages _text,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_organization_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_organization_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_organization_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_organization_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)
	
);

CREATE TABLE osc_physrisk_org.organization_division (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	organization_id uuid NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_organization_division_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_organization_division_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_organization_division_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_organization_division_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)	
);

CREATE INDEX "IX_industry_core_checksum" ON osc_physrisk_org.industry USING btree (core_checksum);

CREATE INDEX "IX_industry_core_culture" ON osc_physrisk_org.industry USING btree (core_culture);

CREATE INDEX "IX_industry_core_data_set_id" ON osc_physrisk_org.industry USING btree (core_data_set_id);

CREATE INDEX "IX_industry_core_id" ON osc_physrisk_org.industry USING btree (core_id);

CREATE INDEX "IX_industry_core_user_creator_id" ON osc_physrisk_org.industry USING btree (core_user_creator_id);

CREATE INDEX "IX_industry_core_user_deleter_id" ON osc_physrisk_org.industry USING btree (core_user_deleter_id);

CREATE INDEX "IX_industry_core_user_last_modifier_id" ON osc_physrisk_org.industry USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_organization_core_checksum" ON osc_physrisk_org.organization USING btree (core_checksum);

CREATE INDEX "IX_organization_core_culture" ON osc_physrisk_org.organization USING btree (core_culture);

CREATE INDEX "IX_organization_core_data_set_id" ON osc_physrisk_org.organization USING btree (core_data_set_id);

CREATE INDEX "IX_organization_core_id" ON osc_physrisk_org.organization USING btree (core_id);

CREATE INDEX "IX_organization_core_user_creator_id" ON osc_physrisk_org.organization USING btree (core_user_creator_id);

CREATE INDEX "IX_organization_core_user_deleter_id" ON osc_physrisk_org.organization USING btree (core_user_deleter_id);

CREATE INDEX "IX_organization_core_user_last_modifier_id" ON osc_physrisk_org.organization USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_organization_division_core_checksum" ON osc_physrisk_org.organization_division USING btree (core_checksum);

CREATE INDEX "IX_organization_division_core_culture" ON osc_physrisk_org.organization_division USING btree (core_culture);

CREATE INDEX "IX_organization_division_core_data_set_id" ON osc_physrisk_org.organization_division USING btree (core_data_set_id);

CREATE INDEX "IX_organization_division_core_id" ON osc_physrisk_org.organization_division USING btree (core_id);

CREATE INDEX "IX_organization_division_core_user_creator_id" ON osc_physrisk_org.organization_division USING btree (core_user_creator_id);

CREATE INDEX "IX_organization_division_core_user_deleter_id" ON osc_physrisk_org.organization_division USING btree (core_user_deleter_id);

CREATE INDEX "IX_organization_division_core_user_last_modifier_id" ON osc_physrisk_org.organization_division USING btree (core_user_last_modifier_id);

CREATE UNIQUE INDEX "PK_industry" ON osc_physrisk_org.industry USING btree (core_id);

CREATE UNIQUE INDEX "PK_organization" ON osc_physrisk_org.organization USING btree (core_id);

CREATE UNIQUE INDEX "PK_organization_division" ON osc_physrisk_org.organization_division USING btree (core_id);



-- SCHEMA osc_physrisk_model
CREATE TABLE osc_physrisk_model.peril (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_peril_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_peril_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_peril_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_peril_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)	
);

CREATE TABLE osc_physrisk_model.hazard (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	frequency text NOT NULL,
	peril_id uuid NOT NULL,
	context_is_chronic_or_acute integer NOT NULL,
	context_is_realized_or_projected integer NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_hazard_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_hazard_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),	
	CONSTRAINT fk_hazard_peril_id FOREIGN KEY ( peril_id ) REFERENCES osc_physrisk_model.peril(core_id)	
);
COMMENT ON TABLE osc_physrisk_model.hazard IS 'Contains a list of the physical hazards supported by OS-Climate.';

CREATE TABLE osc_physrisk_model.hazard_indicator_type (
	core_id uuid NOT NULL,
	core_name_short varchar(50),
	core_name_full varchar(255),
	core_name_suffix varchar(12),
	core_name_prefix varchar(12),
	core_description_short varchar(255),
	core_description_full varchar(8096),
	core_tags jsonb,
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5),
	core_checksum varchar(64),
	core_seq_num integer,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
	category text NOT NULL,
	content_collection_ids _uuid,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_hazard_indicator_type_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_indicator_type_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_indicator_type_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_hazard_indicator_type_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)
);

CREATE INDEX "IX_hazard_indicator_type_core_checksum" ON osc_physrisk_model.hazard_indicator_type USING btree (core_checksum);
CREATE INDEX "IX_hazard_indicator_type_core_culture" ON osc_physrisk_model.hazard_indicator_type USING btree (core_culture);
CREATE INDEX "IX_hazard_indicator_type_core_data_set_id" ON osc_physrisk_model.hazard_indicator_type USING btree (core_data_set_id);
CREATE INDEX "IX_hazard_indicator_type_core_id" ON osc_physrisk_model.hazard_indicator_type USING btree (core_id);
CREATE INDEX "IX_hazard_indicator_type_core_user_creator_id" ON osc_physrisk_model.hazard_indicator_type USING btree (core_user_creator_id);
CREATE INDEX "IX_hazard_indicator_type_core_user_deleter_id" ON osc_physrisk_model.hazard_indicator_type USING btree (core_user_deleter_id);
CREATE INDEX "IX_hazard_indicator_type_core_user_last_modifier_id" ON osc_physrisk_model.hazard_indicator_type USING btree (core_user_last_modifier_id);
CREATE UNIQUE INDEX "PK_hazard_indicator_type" ON osc_physrisk_model.hazard_indicator_type USING btree (core_id);


CREATE TABLE osc_physrisk_model.hazard_indicator (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	hazard_id uuid NOT NULL,
	hazard_indicator_type_id uuid NOT NULL,
	unit_of_measure text NOT NULL,
	context_is_chronic_or_acute integer NOT NULL,
	context_is_realized_or_projected integer NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_hazard_indicator_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_indicator_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_indicator_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_hazard_indicator_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),	
	CONSTRAINT fk_hazard_indicator_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_model.hazard(core_id),
	CONSTRAINT fk_hazard_indicator_hazard_indicator_type_id FOREIGN KEY ( hazard_indicator_type_id ) REFERENCES osc_physrisk_model.hazard_indicator_type(core_id)		
);
COMMENT ON TABLE osc_physrisk_model.hazard_indicator IS 'Contains the set of data indicators that a hazard is present, and which are supported by OS-Climate. An indicator must always relate to one particular hazard.';

CREATE TABLE osc_physrisk_model.hazard_model (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	hazard_id uuid NOT NULL,
	model_uri text NOT NULL,
	hazard_indicator_ids _uuid NOT NULL,
	available_scenario_ids _uuid NOT NULL,
	cost_processing_time bigint NOT NULL,
	cost_processing_charges bigint NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_hazard_model_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_model_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_hazard_model_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_hazard_model_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),	
	CONSTRAINT fk_hazard_model_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_model.hazard(core_id)	
);
COMMENT ON TABLE osc_physrisk_model.hazard_model IS 'Contains a list of the hazard models that can be used to assess the presence and risk of a particular hazard, and which are supported by OS-Climate. A hazard model must always relate to one particular hazard but it may support one or multiple indicators.';

CREATE TABLE osc_physrisk_model.impact_type (
	core_id uuid NOT NULL,
	core_name_short varchar(50),
	core_name_full varchar(255),
	core_name_suffix varchar(12),
	core_name_prefix varchar(12),
	core_description_short varchar(255),
	core_description_full varchar(8096),
	core_tags jsonb,
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5),
	core_checksum varchar(64),
	core_seq_num integer,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
	frequency integer NOT NULL,
	nature integer NOT NULL,
	financial_accounting_category integer NOT NULL,
	content_collection_ids _uuid,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_impact_type_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_impact_type_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_impact_type_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_impact_type_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)	
);
COMMENT ON TABLE osc_physrisk_model.impact_type IS 'Contains a list of the potential types of impacts (usually negative) that could result from an asset''s physical risk(s).';

CREATE INDEX "IX_impact_type_core_checksum" ON osc_physrisk_model.impact_type USING btree (core_checksum);
CREATE INDEX "IX_impact_type_core_culture" ON osc_physrisk_model.impact_type USING btree (core_culture);
CREATE INDEX "IX_impact_type_core_data_set_id" ON osc_physrisk_model.impact_type USING btree (core_data_set_id);
CREATE INDEX "IX_impact_type_core_id" ON osc_physrisk_model.impact_type USING btree (core_id);
CREATE INDEX "IX_impact_type_core_user_creator_id" ON osc_physrisk_model.impact_type USING btree (core_user_creator_id);
CREATE INDEX "IX_impact_type_core_user_deleter_id" ON osc_physrisk_model.impact_type USING btree (core_user_deleter_id);
CREATE INDEX "IX_impact_type_core_user_last_modifier_id" ON osc_physrisk_model.impact_type USING btree (core_user_last_modifier_id);
CREATE UNIQUE INDEX "PK_impact_type" ON osc_physrisk_model.impact_type USING btree (core_id);


CREATE TABLE osc_physrisk_model.scenario (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	temporal_historic_year_first smallint,
	temporal_historic_year_last smallint,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_scenario_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_scenario_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_scenario_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_scenario_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)	
);
COMMENT ON TABLE osc_physrisk_model.scenario IS 'Contains a list of the United Nations Intergovernmental Panel on Climate Change (IPCC)-defined climate scenarios (SSPs and RCPs).';

CREATE TABLE osc_physrisk_model.vulnerability_model (
	core_id uuid DEFAULT gen_random_UUID () NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	hazard_model_ids _uuid NOT NULL,
	model_uri text NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_vulnerability_model_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_vulnerability_model_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_vulnerability_model_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_vulnerability_model_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)	
);
COMMENT ON TABLE osc_physrisk_model.vulnerability_model IS 'Contains a list of the vulnerability models that can be used to assess the physical climate risk to assets, and which are supported by OS-Climate. A vulnerability model must support one or more hazard models (effectively, one or more hazards can be assessed).';


CREATE INDEX "IX_hazard_core_checksum" ON osc_physrisk_model.hazard USING btree (core_checksum);

CREATE INDEX "IX_hazard_core_culture" ON osc_physrisk_model.hazard USING btree (core_culture);

CREATE INDEX "IX_hazard_core_data_set_id" ON osc_physrisk_model.hazard USING btree (core_data_set_id);

CREATE INDEX "IX_hazard_core_id" ON osc_physrisk_model.hazard USING btree (core_id);

CREATE INDEX "IX_hazard_core_user_creator_id" ON osc_physrisk_model.hazard USING btree (core_user_creator_id);

CREATE INDEX "IX_hazard_core_user_deleter_id" ON osc_physrisk_model.hazard USING btree (core_user_deleter_id);

CREATE INDEX "IX_hazard_core_user_last_modifier_id" ON osc_physrisk_model.hazard USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_hazard_indicator_core_checksum" ON osc_physrisk_model.hazard_indicator USING btree (core_checksum);

CREATE INDEX "IX_hazard_indicator_core_culture" ON osc_physrisk_model.hazard_indicator USING btree (core_culture);

CREATE INDEX "IX_hazard_indicator_core_data_set_id" ON osc_physrisk_model.hazard_indicator USING btree (core_data_set_id);

CREATE INDEX "IX_hazard_indicator_core_id" ON osc_physrisk_model.hazard_indicator USING btree (core_id);

CREATE INDEX "IX_hazard_indicator_core_user_creator_id" ON osc_physrisk_model.hazard_indicator USING btree (core_user_creator_id);

CREATE INDEX "IX_hazard_indicator_core_user_deleter_id" ON osc_physrisk_model.hazard_indicator USING btree (core_user_deleter_id);

CREATE INDEX "IX_hazard_indicator_core_user_last_modifier_id" ON osc_physrisk_model.hazard_indicator USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_hazard_indicator_hazard_id" ON osc_physrisk_model.hazard_indicator USING btree (hazard_id);

CREATE INDEX "IX_hazard_model_core_checksum" ON osc_physrisk_model.hazard_model USING btree (core_checksum);

CREATE INDEX "IX_hazard_model_core_culture" ON osc_physrisk_model.hazard_model USING btree (core_culture);

CREATE INDEX "IX_hazard_model_core_data_set_id" ON osc_physrisk_model.hazard_model USING btree (core_data_set_id);

CREATE INDEX "IX_hazard_model_core_id" ON osc_physrisk_model.hazard_model USING btree (core_id);

CREATE INDEX "IX_hazard_model_core_user_creator_id" ON osc_physrisk_model.hazard_model USING btree (core_user_creator_id);

CREATE INDEX "IX_hazard_model_core_user_deleter_id" ON osc_physrisk_model.hazard_model USING btree (core_user_deleter_id);

CREATE INDEX "IX_hazard_model_core_user_last_modifier_id" ON osc_physrisk_model.hazard_model USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_hazard_model_hazard_id" ON osc_physrisk_model.hazard_model USING btree (hazard_id);

CREATE INDEX "IX_hazard_peril_id" ON osc_physrisk_model.hazard USING btree (peril_id);

CREATE INDEX "IX_peril_core_checksum" ON osc_physrisk_model.peril USING btree (core_checksum);

CREATE INDEX "IX_peril_core_culture" ON osc_physrisk_model.peril USING btree (core_culture);

CREATE INDEX "IX_peril_core_data_set_id" ON osc_physrisk_model.peril USING btree (core_data_set_id);

CREATE INDEX "IX_peril_core_id" ON osc_physrisk_model.peril USING btree (core_id);

CREATE INDEX "IX_peril_core_user_creator_id" ON osc_physrisk_model.peril USING btree (core_user_creator_id);

CREATE INDEX "IX_peril_core_user_deleter_id" ON osc_physrisk_model.peril USING btree (core_user_deleter_id);

CREATE INDEX "IX_peril_core_user_last_modifier_id" ON osc_physrisk_model.peril USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_scenario_core_checksum" ON osc_physrisk_model.scenario USING btree (core_checksum);

CREATE INDEX "IX_scenario_core_culture" ON osc_physrisk_model.scenario USING btree (core_culture);

CREATE INDEX "IX_scenario_core_data_set_id" ON osc_physrisk_model.scenario USING btree (core_data_set_id);

CREATE INDEX "IX_scenario_core_id" ON osc_physrisk_model.scenario USING btree (core_id);

CREATE INDEX "IX_scenario_core_user_creator_id" ON osc_physrisk_model.scenario USING btree (core_user_creator_id);

CREATE INDEX "IX_scenario_core_user_deleter_id" ON osc_physrisk_model.scenario USING btree (core_user_deleter_id);

CREATE INDEX "IX_scenario_core_user_last_modifier_id" ON osc_physrisk_model.scenario USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_vulnerability_model_core_checksum" ON osc_physrisk_model.vulnerability_model USING btree (core_checksum);

CREATE INDEX "IX_vulnerability_model_core_culture" ON osc_physrisk_model.vulnerability_model USING btree (core_culture);

CREATE INDEX "IX_vulnerability_model_core_data_set_id" ON osc_physrisk_model.vulnerability_model USING btree (core_data_set_id);

CREATE INDEX "IX_vulnerability_model_core_id" ON osc_physrisk_model.vulnerability_model USING btree (core_id);

CREATE INDEX "IX_vulnerability_model_core_user_creator_id" ON osc_physrisk_model.vulnerability_model USING btree (core_user_creator_id);

CREATE INDEX "IX_vulnerability_model_core_user_deleter_id" ON osc_physrisk_model.vulnerability_model USING btree (core_user_deleter_id);

CREATE INDEX "IX_vulnerability_model_core_user_last_modifier_id" ON osc_physrisk_model.vulnerability_model USING btree (core_user_last_modifier_id);

CREATE UNIQUE INDEX "PK_hazard" ON osc_physrisk_model.hazard USING btree (core_id);

CREATE UNIQUE INDEX "PK_hazard_indicator" ON osc_physrisk_model.hazard_indicator USING btree (core_id);

CREATE UNIQUE INDEX "PK_hazard_model" ON osc_physrisk_model.hazard_model USING btree (core_id);

CREATE UNIQUE INDEX "PK_peril" ON osc_physrisk_model.peril USING btree (core_id);

CREATE UNIQUE INDEX "PK_scenario" ON osc_physrisk_model.scenario USING btree (core_id);

CREATE UNIQUE INDEX "PK_vulnerability_model" ON osc_physrisk_model.vulnerability_model USING btree (core_id);


-- CREATE SCHEMA osc_physrisk_assets
CREATE TABLE osc_physrisk_assets.asset_class (
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_asset_class_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_class_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_class_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_asset_class_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)	
);
COMMENT ON TABLE osc_physrisk_assets.asset_class IS 'A physical financial asset (infrastructure, utilities, property, buildings) category, that may impact the modeling (ex real estate vs power generating utilities).';

CREATE TABLE osc_physrisk_assets.asset_type (
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	asset_class_id uuid NOT NULL,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_asset_type_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_type_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_type_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_asset_type_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_generic_asset_asset_class_id FOREIGN KEY ( asset_class_id ) REFERENCES osc_physrisk_assets.asset_class(core_id)	
);
COMMENT ON TABLE osc_physrisk_assets.asset_type IS 'A physical financial asset (infrastructure, utilities, property, buildings) specific classification within an overarching asset class, that may impact the modeling (ex commercial real estate vs residential real, both of which types belong to the same real estate class).';

CREATE TABLE osc_physrisk_assets.construction_type (
	core_id uuid NOT NULL,
	core_name_short varchar(50),
	core_name_full varchar(255),
	core_name_suffix varchar(12),
	core_name_prefix varchar(12),
	core_description_short varchar(255),
	core_description_full varchar(8096),
	core_tags jsonb,
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5),
	core_checksum varchar(64),
	core_seq_num integer,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
	open_exposure_data_oed_code integer NOT NULL,
	open_exposure_data_cede_code varchar(50) NOT NULL,
	open_exposure_data_code_range varchar(50) NOT NULL,
	open_exposure_data_broad_category varchar(50) NOT NULL,
	content_collection_ids _uuid,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_construction_type_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_construction_type_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_construction_type_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_construction_type_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id)
);
COMMENT ON TABLE osc_physrisk_assets.construction_type IS 'The type of construction method or material an asset is made of, helpful for determining vulnerability or exposure.';

CREATE INDEX "IX_construction_type_core_checksum" ON osc_physrisk_assets.construction_type USING btree (core_checksum);
CREATE INDEX "IX_construction_type_core_culture" ON osc_physrisk_assets.construction_type USING btree (core_culture);
CREATE INDEX "IX_construction_type_core_data_set_id" ON osc_physrisk_assets.construction_type USING btree (core_data_set_id);
CREATE INDEX "IX_construction_type_core_id" ON osc_physrisk_assets.construction_type USING btree (core_id);
CREATE INDEX "IX_construction_type_core_user_creator_id" ON osc_physrisk_assets.construction_type USING btree (core_user_creator_id);
CREATE INDEX "IX_construction_type_core_user_deleter_id" ON osc_physrisk_assets.construction_type USING btree (core_user_deleter_id);
CREATE INDEX "IX_construction_type_core_user_last_modifier_id" ON osc_physrisk_assets.construction_type USING btree (core_user_last_modifier_id);
CREATE UNIQUE INDEX "PK_construction_type" ON osc_physrisk_assets.construction_type USING btree (core_id);

CREATE TABLE osc_physrisk_assets.generic_asset (
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_spatial_geometry geometry,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_tenant_id bigint,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	asset_class_id uuid NOT NULL,
	asset_type_id uuid NOT NULL,
	country_id uuid,
	core_spatial_location_address text,
	core_spatial_location_name text,
	core_spatial_bbox _float8,
	core_spatial_elevation float8,
	core_spatial_area_minimum float8,
	core_spatial_area_maximum float8,
	core_spatial_area_unit_of_measure varchar(64),
	core_spatial_area_confidence float8,
	core_spatial_height_minimum float8,
	core_spatial_height_maximum float8,
	core_spatial_height_unit_of_measure varchar(64),
	core_spatial_height_confidence float8,
	core_spatial_elevation_minimum float8,
	core_spatial_elevation_maximum float8,
	core_spatial_elevation_unit_of_measure varchar(64),
	core_spatial_elevation_confidence float8,
	core_spatial_h3_index integer,
	core_spatial_h3_resolution integer,
	core_spatial_overture_gers_id uuid,
	core_spatial_overture_features jsonb,
	parent_name text,
	core_temporal_datetime_utc_effective timestamptz,
	core_temporal_datetime_utc_start timestamptz,
	core_temporal_datetime_utc_end timestamptz,
	details_json jsonb,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_generic_asset_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_generic_asset_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_generic_asset_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_generic_asset_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_generic_asset_asset_class_id FOREIGN KEY ( asset_class_id ) REFERENCES osc_physrisk_assets.asset_class(core_id),
	CONSTRAINT fk_generic_asset_asset_type_id FOREIGN KEY ( asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(core_id),
	CONSTRAINT fk_generic_asset_country_id FOREIGN KEY ( country_id ) REFERENCES osc_physrisk_backend.country(core_id),
	CONSTRAINT fk_asset_powergeneratingutility_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id)
);
COMMENT ON TABLE osc_physrisk_assets.generic_asset IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is contained within a financial portfolio and not further classified by its Asset Type (otherwise use a more specific, relevant table). The lowest unit of assessment for physical risk & resilience (currently).';


CREATE TABLE osc_physrisk_assets.asset_construction (
	core_id uuid NOT NULL,
	core_name_short varchar(50),
	core_name_full varchar(255),
	core_name_suffix varchar(12),
	core_name_prefix varchar(12),
	core_description_short varchar(255),
	core_description_full varchar(8096),
	core_tags jsonb,
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5),
	core_checksum varchar(64),
	core_seq_num integer,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
	asset_id uuid NOT NULL,
	primary_construction_type_id uuid NOT NULL,
	secondary_construction_type_id uuid,
	content_collection_ids _uuid,
	details_json jsonb,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_asset_construction_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_construction_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_construction_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_asset_construction_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_asset_construction_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.generic_asset(core_id),
	CONSTRAINT fk_asset_construction_primary_construction_type_id FOREIGN KEY ( primary_construction_type_id ) REFERENCES osc_physrisk_assets.construction_type(core_id),
	CONSTRAINT fk_asset_construction_secondary_construction_type_id FOREIGN KEY ( secondary_construction_type_id ) REFERENCES osc_physrisk_assets.construction_type(core_id)
);
COMMENT ON TABLE osc_physrisk_assets.asset_construction IS 'Helps define variables related to the type of construction of an asset, such as its material or manufacturing method, which can help establish potential vulnerability or exposure.';

CREATE INDEX "IX_asset_construction_asset_id" ON osc_physrisk_assets.asset_construction USING btree (asset_id);
CREATE INDEX "IX_asset_construction_core_checksum" ON osc_physrisk_assets.asset_construction USING btree (core_checksum);
CREATE INDEX "IX_asset_construction_core_culture" ON osc_physrisk_assets.asset_construction USING btree (core_culture);
CREATE INDEX "IX_asset_construction_core_data_set_id" ON osc_physrisk_assets.asset_construction USING btree (core_data_set_id);
CREATE INDEX "IX_asset_construction_core_id" ON osc_physrisk_assets.asset_construction USING btree (core_id);
CREATE INDEX "IX_asset_construction_core_user_creator_id" ON osc_physrisk_assets.asset_construction USING btree (core_user_creator_id);
CREATE INDEX "IX_asset_construction_core_user_deleter_id" ON osc_physrisk_assets.asset_construction USING btree (core_user_deleter_id);
CREATE INDEX "IX_asset_construction_core_user_last_modifier_id" ON osc_physrisk_assets.asset_construction USING btree (core_user_last_modifier_id);
CREATE INDEX "IX_asset_construction_primary_construction_type_id" ON osc_physrisk_assets.asset_construction USING btree (primary_construction_type_id);
CREATE INDEX "IX_asset_construction_secondary_construction_type_id" ON osc_physrisk_assets.asset_construction USING btree (secondary_construction_type_id);
CREATE UNIQUE INDEX "PK_asset_construction" ON osc_physrisk_assets.asset_construction USING btree (core_id);

CREATE TABLE osc_physrisk_assets.asset_operator (
	core_id uuid NOT NULL,
	core_name_short varchar(50),
	core_name_full varchar(255),
	core_name_suffix varchar(12),
	core_name_prefix varchar(12),
	core_description_short varchar(255),
	core_description_full varchar(8096),
	core_tags jsonb,
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5),
	core_checksum varchar(64),
	core_seq_num integer,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
	asset_id uuid NOT NULL,
	contact_name varchar(255),
	contact_type text,
	contact_email _text,
	contact_fax text,
	contact_telephone _text,
	contact_available_languages _text,
	organization_id uuid NOT NULL,
	content_collection_ids _uuid,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_asset_operator_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_operator_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_operator_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_asset_operator_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_asset_operator_core_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.generic_asset(core_id),
	CONSTRAINT fk_asset_operator_organization_id FOREIGN KEY ( organization_id ) REFERENCES osc_physrisk_org.organization(core_id)	
);
COMMENT ON TABLE osc_physrisk_assets.asset_operator IS 'Information tracking asset operation information, including the organization in charge of its principal maintenance and operation.';

CREATE INDEX "IX_asset_operator_asset_id" ON osc_physrisk_assets.asset_operator USING btree (asset_id);
CREATE INDEX "IX_asset_operator_core_checksum" ON osc_physrisk_assets.asset_operator USING btree (core_checksum);
CREATE INDEX "IX_asset_operator_core_culture" ON osc_physrisk_assets.asset_operator USING btree (core_culture);
CREATE INDEX "IX_asset_operator_core_data_set_id" ON osc_physrisk_assets.asset_operator USING btree (core_data_set_id);
CREATE INDEX "IX_asset_operator_core_id" ON osc_physrisk_assets.asset_operator USING btree (core_id);
CREATE INDEX "IX_asset_operator_core_user_creator_id" ON osc_physrisk_assets.asset_operator USING btree (core_user_creator_id);
CREATE INDEX "IX_asset_operator_core_user_deleter_id" ON osc_physrisk_assets.asset_operator USING btree (core_user_deleter_id);
CREATE INDEX "IX_asset_operator_core_user_last_modifier_id" ON osc_physrisk_assets.asset_operator USING btree (core_user_last_modifier_id);
CREATE INDEX "IX_asset_operator_organization_id" ON osc_physrisk_assets.asset_operator USING btree (organization_id);
CREATE UNIQUE INDEX "PK_asset_operator" ON osc_physrisk_assets.asset_operator USING btree (core_id);

CREATE TABLE osc_physrisk_assets.asset_owner (
	core_id uuid NOT NULL,
	core_name_short varchar(50),
	core_name_full varchar(255),
	core_name_suffix varchar(12),
	core_name_prefix varchar(12),
	core_description_short varchar(255),
	core_description_full varchar(8096),
	core_tags jsonb,
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5),
	core_checksum varchar(64),
	core_seq_num integer,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
	asset_id uuid NOT NULL,
	contact_name varchar(255),
	contact_type text,
	contact_email _text,
	contact_fax text,
	contact_telephone _text,
	contact_available_languages _text,
	organization_id uuid NOT NULL,
	content_collection_ids _uuid,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_asset_owner_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_owner_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_owner_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_asset_owner_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_asset_owner_core_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.generic_asset(core_id),
	CONSTRAINT fk_asset_owner_organization_id FOREIGN KEY ( organization_id ) REFERENCES osc_physrisk_org.organization(core_id)	
);
COMMENT ON TABLE osc_physrisk_assets.asset_owner IS 'Information tracking asset operation information, including the organization in charge of its principal maintenance and operation.';

CREATE INDEX "IX_asset_owner_asset_id" ON osc_physrisk_assets.asset_owner USING btree (asset_id);
CREATE INDEX "IX_asset_owner_core_checksum" ON osc_physrisk_assets.asset_owner USING btree (core_checksum);
CREATE INDEX "IX_asset_owner_core_culture" ON osc_physrisk_assets.asset_owner USING btree (core_culture);
CREATE INDEX "IX_asset_owner_core_data_set_id" ON osc_physrisk_assets.asset_owner USING btree (core_data_set_id);
CREATE INDEX "IX_asset_owner_core_id" ON osc_physrisk_assets.asset_owner USING btree (core_id);
CREATE INDEX "IX_asset_owner_core_user_creator_id" ON osc_physrisk_assets.asset_owner USING btree (core_user_creator_id);
CREATE INDEX "IX_asset_owner_core_user_deleter_id" ON osc_physrisk_assets.asset_owner USING btree (core_user_deleter_id);
CREATE INDEX "IX_asset_owner_core_user_last_modifier_id" ON osc_physrisk_assets.asset_owner USING btree (core_user_last_modifier_id);
CREATE INDEX "IX_asset_owner_organization_id" ON osc_physrisk_assets.asset_owner USING btree (organization_id);
CREATE UNIQUE INDEX "PK_asset_owner" ON osc_physrisk_assets.asset_owner USING btree (core_id);


CREATE TABLE osc_physrisk_assets.portfolio (
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	organization_id uuid NOT NULL,
	portfolio_owner_user_id bigint NOT NULL,
	asset_value numeric(10,2) NOT NULL,
	details_json jsonb,
	PRIMARY KEY (core_id),
	CONSTRAINT fk_portfolio_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_portfolio_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_portfolio_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
 	CONSTRAINT fk_portfolio_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_portfolio_organization_id FOREIGN KEY ( organization_id ) REFERENCES osc_physrisk_org.organization(core_id),
	CONSTRAINT fk_portfolio_portfolio_owner_id FOREIGN KEY ( portfolio_owner_user_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_powergeneratingutility_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id)
);
COMMENT ON TABLE osc_physrisk_assets.portfolio IS 'A financial portfolio that contains 1 or more physical financial assets (infrastructure, utilities, property, buildings).';

CREATE TABLE osc_physrisk_assets.bridge_portfolio_asset (
	portfolio_id uuid NOT NULL,
	asset_id uuid NOT NULL,
	details_json jsonb,
	PRIMARY KEY (portfolio_id,asset_id),
	CONSTRAINT fk_bridge_portfolio_asset_portfolio_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(core_id)
	--CONSTRAINT fk_bridge_portfolio_asset_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.generic_asset(core_id)	
);


CREATE INDEX "IX_asset_class_core_checksum" ON osc_physrisk_assets.asset_class USING btree (core_checksum);

CREATE INDEX "IX_asset_class_core_culture" ON osc_physrisk_assets.asset_class USING btree (core_culture);

CREATE INDEX "IX_asset_class_core_data_set_id" ON osc_physrisk_assets.asset_class USING btree (core_data_set_id);

CREATE INDEX "IX_asset_class_core_id" ON osc_physrisk_assets.asset_class USING btree (core_id);

CREATE INDEX "IX_asset_class_core_user_creator_id" ON osc_physrisk_assets.asset_class USING btree (core_user_creator_id);

CREATE INDEX "IX_asset_class_core_user_deleter_id" ON osc_physrisk_assets.asset_class USING btree (core_user_deleter_id);

CREATE INDEX "IX_asset_class_core_user_last_modifier_id" ON osc_physrisk_assets.asset_class USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_asset_type_asset_class_id" ON osc_physrisk_assets.asset_type USING btree (asset_class_id);

CREATE INDEX "IX_asset_type_core_checksum" ON osc_physrisk_assets.asset_type USING btree (core_checksum);

CREATE INDEX "IX_asset_type_core_culture" ON osc_physrisk_assets.asset_type USING btree (core_culture);

CREATE INDEX "IX_asset_type_core_data_set_id" ON osc_physrisk_assets.asset_type USING btree (core_data_set_id);

CREATE INDEX "IX_asset_type_core_id" ON osc_physrisk_assets.asset_type USING btree (core_id);

CREATE INDEX "IX_asset_type_core_user_creator_id" ON osc_physrisk_assets.asset_type USING btree (core_user_creator_id);

CREATE INDEX "IX_asset_type_core_user_deleter_id" ON osc_physrisk_assets.asset_type USING btree (core_user_deleter_id);

CREATE INDEX "IX_asset_type_core_user_last_modifier_id" ON osc_physrisk_assets.asset_type USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_bridge_portfolio_asset_asset_id" ON osc_physrisk_assets.bridge_portfolio_asset USING btree (asset_id);

CREATE INDEX "IX_generic_asset_asset_class_id" ON osc_physrisk_assets.generic_asset USING btree (asset_class_id);

CREATE INDEX "IX_generic_asset_asset_type_id" ON osc_physrisk_assets.generic_asset USING btree (asset_type_id);

CREATE INDEX "IX_generic_asset_core_checksum" ON osc_physrisk_assets.generic_asset USING btree (core_checksum);

CREATE INDEX "IX_generic_asset_core_culture" ON osc_physrisk_assets.generic_asset USING btree (core_culture);

CREATE INDEX "IX_generic_asset_core_data_set_id" ON osc_physrisk_assets.generic_asset USING btree (core_data_set_id);

CREATE INDEX "IX_generic_asset_core_id" ON osc_physrisk_assets.generic_asset USING btree (core_id);

CREATE INDEX "IX_generic_asset_core_user_creator_id" ON osc_physrisk_assets.generic_asset USING btree (core_user_creator_id);

CREATE INDEX "IX_generic_asset_core_user_deleter_id" ON osc_physrisk_assets.generic_asset USING btree (core_user_deleter_id);

CREATE INDEX "IX_generic_asset_core_user_last_modifier_id" ON osc_physrisk_assets.generic_asset USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_portfolio_portfolio_owner_user_id" ON osc_physrisk_assets.portfolio USING btree (portfolio_owner_user_id);

CREATE INDEX "IX_portfolio_core_checksum" ON osc_physrisk_assets.portfolio USING btree (core_checksum);

CREATE INDEX "IX_portfolio_core_culture" ON osc_physrisk_assets.portfolio USING btree (core_culture);

CREATE INDEX "IX_portfolio_core_data_set_id" ON osc_physrisk_assets.portfolio USING btree (core_data_set_id);

CREATE INDEX "IX_portfolio_core_id" ON osc_physrisk_assets.portfolio USING btree (core_id);

CREATE INDEX "IX_portfolio_core_user_creator_id" ON osc_physrisk_assets.portfolio USING btree (core_user_creator_id);

CREATE INDEX "IX_portfolio_core_user_deleter_id" ON osc_physrisk_assets.portfolio USING btree (core_user_deleter_id);

CREATE INDEX "IX_portfolio_core_user_last_modifier_id" ON osc_physrisk_assets.portfolio USING btree (core_user_last_modifier_id);

CREATE INDEX "IX_portfolio_organization_id" ON osc_physrisk_assets.portfolio USING btree (organization_id);

CREATE UNIQUE INDEX "PK_asset_class" ON osc_physrisk_assets.asset_class USING btree (core_id);

CREATE UNIQUE INDEX "PK_asset_type" ON osc_physrisk_assets.asset_type USING btree (core_id);

CREATE UNIQUE INDEX "PK_bridge_portfolio_asset" ON osc_physrisk_assets.bridge_portfolio_asset USING btree (portfolio_id, asset_id);

CREATE UNIQUE INDEX "PK_generic_asset" ON osc_physrisk_assets.generic_asset USING btree (core_id);

CREATE UNIQUE INDEX "PK_portfolio" ON osc_physrisk_assets.portfolio USING btree (core_id);


CREATE TABLE osc_physrisk_assets.asset_realestate ( 
	value_cashflows numeric ARRAY,-- Sequence of the associated cash flows (for cash flow generating assets only).
    value_loan text ARRAY, -- Sequence of Loans by date, representing the mortgage lines
	value_ltv text ARRAY, -- Sequence of Loan-to-Value results by date, representing the ratio of the first mortgage line as a percentage of the total appraised value of real property.
	CONSTRAINT pk_asset_realestate PRIMARY KEY ( core_id ),
	CONSTRAINT fk_asset_realestate_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT ck_asset_realestate_h3_resolution CHECK (core_spatial_h3_resolution >= 0 AND core_spatial_h3_resolution <= 15),
	CONSTRAINT fk_asset_realestate_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_realestate_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_realestate_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_realestate_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id),	
    CONSTRAINT fk_asset_realestate_asset_type_id FOREIGN KEY ( asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(core_id)
 ) INHERITS (osc_physrisk_assets.generic_asset);
COMMENT ON TABLE osc_physrisk_assets.asset_realestate IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is of the Real Estate asset type and contained within a financial portfolio. The lowest unit of assessment for physical risk & resilience (currently).';

CREATE TABLE osc_physrisk_assets.asset_powergeneratingutility ( 
	production numeric NOT NULL, -- Real annual production of a power plant in Wh.
	capacity numeric NOT NULL, -- Capacity of the power plant in W.
	availability_rate numeric NOT NULL, -- Availability factor of production.
	CONSTRAINT pk_asset_powergeneratingutility PRIMARY KEY ( core_id ),
	CONSTRAINT fk_asset_powergeneratingutility_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT ck_asset_powergeneratingutility_h3_resolution CHECK (core_spatial_h3_resolution >= 0 AND core_spatial_h3_resolution <= 15),
	CONSTRAINT fk_asset_powergeneratingutility_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_powergeneratingutility_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_powergeneratingutilitycore_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_powergeneratingutility_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id),	
    CONSTRAINT fk_asset_powergeneratingutility_asset_type_id FOREIGN KEY ( asset_type_id ) REFERENCES osc_physrisk_assets.asset_type(core_id)
 ) INHERITS (osc_physrisk_assets.generic_asset);
COMMENT ON TABLE osc_physrisk_assets.asset_powergeneratingutility IS 'A physical financial asset (infrastructure, utilities, property, buildings) that is of the Power Generating Utility asset type and contained within a financial portfolio. The lowest unit of assessment for physical risk & resilience (currently).';

CREATE TABLE osc_physrisk_model.exposure_function ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	CONSTRAINT pk_exposure_function PRIMARY KEY ( core_id ),
	CONSTRAINT fk_exposure_function_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_exposure_function_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_exposure_function_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_exposure_function_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_exposure_function_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id)
 );
 COMMENT ON TABLE osc_physrisk_model.exposure_function IS 'The model used to determine whether a particular asset is exposed to a particular hazard indicator.';


CREATE TABLE osc_physrisk_model.vulnerability_type ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
    accounting_category VARCHAR(255),
	CONSTRAINT pk_vulnerability_type PRIMARY KEY ( core_id ),
	CONSTRAINT fk_vulnerability_type_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_vulnerability_type_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_vulnerability_type_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_vulnerability_type_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id)
 ); 
COMMENT ON TABLE osc_physrisk_model.vulnerability_type IS 'A lookup table to classify and constrain types of damage/disruption that could occur to an asset due to its vulnerability to a hazard.';

CREATE TABLE osc_physrisk_model.vulnerability_function ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	CONSTRAINT pk_vulnerability_function PRIMARY KEY ( core_id ),
	CONSTRAINT fk_vulnerability_function_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_vulnerability_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_vulnerability_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_vulnerability_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_vulnerability_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id)
 );
COMMENT ON TABLE osc_physrisk_model.vulnerability_function IS 'The model used to determine the degree by which a particular asset is vulnerable to a particular hazard indicator. If an asset is vulnerable to a peril, it must necessarily be exposed to it (see exposure_function).';



-- SCHEMA osc_physrisk_analysis;
CREATE TABLE osc_physrisk_analysis.financial_function ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	CONSTRAINT pk_financial_function PRIMARY KEY ( core_id ),
	CONSTRAINT fk_financial_function_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_financial_function_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_financial_function_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_financial_function_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_financial_function_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id)
 );
COMMENT ON TABLE osc_physrisk_analysis.financial_function IS 'Related to osc_physrisk_analysis';

CREATE TABLE osc_physrisk_analysis.financial_impact_type ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
    accounting_category VARCHAR(255),
	CONSTRAINT pk_financial_impact_type PRIMARY KEY ( core_id ),
	CONSTRAINT fk_financial_impact_type_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_financial_impact_type_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_financial_impact_type_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_financial_impact_type_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id)
 ); 
COMMENT ON TABLE osc_physrisk_analysis.financial_impact_type IS 'A lookup table to classify and constrain types of damage/disruption that could occur to an asset due to its vulnerability to a hazard.';

CREATE TABLE osc_physrisk_analysis.portfolio_financial_impact ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	portfolio_id            UUID  NOT NULL  ,
	scenario_id UUID NOT NULL,
    scenario_year smallint,
	hazard_id	UUID NOT NULL,
	annual_exceedence_probability numeric,
	average_annual_loss numeric,
    value_total numeric,
    value_at_risk numeric,
    value_currency_alphabetic_code char(3),
	CONSTRAINT pk_portfolio_financial_impact PRIMARY KEY ( core_id ),
	CONSTRAINT fk_portfolio_financial_impact_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_core_id FOREIGN KEY ( portfolio_id ) REFERENCES osc_physrisk_assets.portfolio(core_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_model.scenario(core_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_hazard_id FOREIGN KEY ( hazard_id ) REFERENCES osc_physrisk_model.hazard(core_id)   ,
	CONSTRAINT fk_portfolio_financial_impact_analysis_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_portfolio_financial_impact_analysis_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id)  ,
	CONSTRAINT fk_portfolio_financial_impact_analysis_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id)
 );
COMMENT ON TABLE osc_physrisk_analysis.portfolio_financial_impact IS 'The result of a physical risk & resilience analysis. The result is determined by the chosen scenario, year, and hazard, aggregating the results for all of the assets in a given portfolio. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results.';

CREATE TABLE osc_physrisk_analysis.asset_financial_impact ( 
	core_id uuid DEFAULT gen_random_UUID ()  NOT NULL,
	core_description_full varchar(8096) NOT NULL,
	core_description_short varchar(255),
	core_name_full varchar(255),
	core_name_prefix varchar(12),
	core_name_short varchar(50),
	core_name_suffix varchar(12),
	core_temporal_datetime_utc_created timestamptz NOT NULL,
	core_tenant_id bigint,
	core_user_creator_id bigint,
	core_temporal_datetime_utc_last_modified timestamptz,
	core_user_last_modifier_id bigint,
	core_is_deleted bool NOT NULL,
	core_user_deleter_id bigint,
	core_temporal_datetime_utc_deleted timestamptz,
	core_culture varchar(5) NOT NULL,
	core_checksum varchar(64),
	core_seq_num integer,
	core_tags jsonb,
	core_translated_from_id uuid,
	core_is_active bool NOT NULL,
	core_data_set_id uuid NOT NULL,
	core_spatial_country_id UUID,
	core_spatial_location_name      	VARCHAR(255),
    core_spatial_location_address      	text ,
    core_spatial_location_coordinates      	GEOGRAPHY  NOT NULL  ,
	core_spatial_overture_features			jsonb[], -- This location can be described in 0 or more Overture Map schemas to cover its land use, infrastructure, building extents, etc
	core_spatial_h3_index H3INDEX NOT NULL,
    core_spatial_h3_resolution INT2 NOT NULL,
	core_datetime_utc_start timestamptz,
	core_datetime_utc_end timestamptz,	
	asset_id            UUID  NOT NULL  ,
	hazard_indicator_id UUID NOT NULL,
    hazard_intensity numeric[], -- Assume this includes intensity units
	scenario_id UUID NOT NULL,
    scenario_year smallint,
    vulnerability_type_id UUID NOT NULL,
	financial_impact_type_id UUID NOT NULL, -- this design assumes one row per impact type. If there are multiple potential impact types, there would be multiple rows.
	impact_data_raw jsonb NOT NULL, -- we recommend that this json includes schema references so a consuming application can use json schema for parsing.	
    impact_level numeric NOT NULL, -- 0.0 = not vulnerable at all 1.0 = highly vulnerable across whole area. In  between = some level of vulnerability, finer geographic granularity is required	
	impact_mean    numeric[],
	impact_std    numeric[],
	impact_distribution_bin_edges    numeric[],
    impact_distribution_probabilities    numeric[],
	impact_exceedance_probabilities    numeric[], -- X axis info, redundant but useful
	impact_return_periods jsonb, -- useful?	
	value_total numeric,
    value_at_risk numeric,
    value_currency_alphabetic_code char(3),
    --parameter    numeric,
    exposure_function_id text NOT NULL,
	exposure_result_raw jsonb NOT NULL, -- STORE RAW JSON, MAYBE OVERLAP WITH SOME COLUMNS BELOW?
	exposure_probability numeric,
	exposure_level bool,	
	vulnerability_function_id UUID NOT NULL,
	CONSTRAINT pk_asset_financial_impact PRIMARY KEY ( core_id ),
	CONSTRAINT fk_asset_financial_impact_core_data_set_id FOREIGN KEY ( core_data_set_id ) REFERENCES osc_physrisk_backend.data_set(core_id),
    CONSTRAINT fk_asset_financial_impact_country_id FOREIGN KEY ( core_spatial_country_id ) REFERENCES osc_physrisk_backend.country(core_id),
	CONSTRAINT ck_asset_financial_impact_geo_h3_resolution CHECK (core_spatial_h3_resolution >= 0 AND core_spatial_h3_resolution <= 15),
	CONSTRAINT fk_asset_financial_impact_asset_id FOREIGN KEY ( asset_id ) REFERENCES osc_physrisk_assets.generic_asset(core_id),
	CONSTRAINT fk_asset_financial_impact_scenario_id FOREIGN KEY ( scenario_id ) REFERENCES osc_physrisk_model.scenario(core_id),
	CONSTRAINT fk_asset_financial_impact_vulnerability_type_id FOREIGN KEY ( vulnerability_type_id ) REFERENCES osc_physrisk_model.vulnerability_type(core_id),
	CONSTRAINT fk_asset_financial_impact_financial_impact_type_id FOREIGN KEY ( financial_impact_type_id ) REFERENCES osc_physrisk_analysis.financial_impact_type(core_id),
	CONSTRAINT fk_asset_financial_impact_hazard_indicator_id FOREIGN KEY ( hazard_indicator_id ) REFERENCES osc_physrisk_model.hazard_indicator(core_id)    ,
	CONSTRAINT fk_asset_financial_impact_core_vulnerability_function_id FOREIGN KEY ( vulnerability_function_id ) REFERENCES osc_physrisk_model.vulnerability_function(core_id),	
	CONSTRAINT fk_asset_financial_impact_core_user_creator_id FOREIGN KEY ( core_user_creator_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_financial_impact_core_user_last_modifier_id FOREIGN KEY ( core_user_last_modifier_id ) REFERENCES osc_physrisk_backend.user(core_id),
	CONSTRAINT fk_asset_financial_impact_core_user_deleter_id FOREIGN KEY ( core_user_deleter_id ) REFERENCES osc_physrisk_backend.user(core_id)   ,
	CONSTRAINT fk_asset_financial_impact_core_tenant_id FOREIGN KEY ( core_tenant_id ) REFERENCES osc_physrisk_backend.tenant(core_id)
 );
COMMENT ON TABLE osc_physrisk_analysis.asset_financial_impact IS 'The financial impact result of a physical risk & resilience analysis for a particular asset. The result is determined by the chosen scenario, year, and hazard. If multiple scenarios/years/hazards were chosen, there will be multiple other rows containing the combined set of results. A financial impact can only occur if there is a corresponding impact row (see asset_vulnerability table)';


-- SETUP PERMISSIONS FOR A READER SQL SERVICE ACCOUNT (CREATE THAT USING A DATABASE TOOL)
--GRANT USAGE ON SCHEMA "osc_physrisk_backend" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_backend" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_org" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_org" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_model" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_model" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_assets" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_assets" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_analysis" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_analysis" TO physrisk_reader_service;
--GRANT USAGE ON SCHEMA "osc_physrisk_analysis" TO physrisk_reader_service;
--GRANT SELECT ON ALL TABLES IN SCHEMA "osc_physrisk_analysis" TO physrisk_reader_service;

-- SETUP PERMISSIONS FOR A READER/WRITER SQL SERVICE ACCOUNT (CREATE THAT USING A DATABASE TOOL)
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_backend" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_backend" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_org" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_org" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_model" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_model" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_assets" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_assets" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_analysis" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_analysis" TO physrisk_readerwriter_service;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "osc_physrisk_analysis" TO physrisk_readerwriter_service;
--GRANT ALL ON ALL TABLES IN SCHEMA "osc_physrisk_analysis" TO physrisk_readerwriter_service;
