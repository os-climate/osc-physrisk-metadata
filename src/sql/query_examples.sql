-- EXAMPLE QUERIES
-- VIEW SCENARIOS IN DIFFERENT LANGUAGES
SELECT * FROM osc_physrisk_model.scenario WHERE core_culture='en';
SELECT * FROM osc_physrisk_model.scenario WHERE core_culture='fr';
SELECT * FROM osc_physrisk_model.scenario WHERE core_culture='es';

SELECT a.core_name_short as "English core_name_short",  b.core_culture as "Translated core_culture",  b.core_name_short as "Translated core_name_short", b.core_description_full as "Translated Description", b.core_tags as "Translated core_tags" FROM osc_physrisk_model.scenario a 
INNER JOIN osc_physrisk_model.scenario b ON a.core_id = b.core_translated_from_id
WHERE b.core_culture='es'  ;

-- QUERY BY core_tags EXAMPLE: FIND ASSETS WITH A CERTAIN NAICS OR OED OCCUPANCY VALUE (SHOWS HOW TO SUPPORT MULTIPLE STANDARDS)
SELECT a.core_name_full,  a.core_description_full, a.core_tags, b.core_name_short as asset_class FROM osc_physrisk_asset.asset_powergeneratingutility a INNER JOIN osc_physrisk_asset.asset_class b ON a.core_id = b.core_id
--WHERE a.core_tags -> 'naics'='22111' OR a.core_tags -> 'oed:occupancy:oed_code'='1300' OR a.core_tags -> 'oed:occupancy:air_code'='361' 
;

SELECT a.core_name_full,  a.core_description_full, a.core_tags, b.core_name_short as asset_class FROM osc_physrisk_asset.asset_powergeneratingutility a INNER JOIN osc_physrisk_asset.asset_class b ON a.core_id = b.core_id
WHERE a.core_tags -> 'naics' =  '53'
 ;

-- QUERY BY core_tags EXAMPLE: FIND SCENARIOS WITH CERTAIN core_tags
SELECT a.core_name_full,  a.core_description_full, a.core_tags FROM osc_physrisk_model.scenario a
WHERE a.core_tags -> 'key1'='"value1"' OR a.core_tags -> 'key2'='"value4"'  
;

-- VIEW RIVERINE INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	osc_physrisk_model.hazard haz INNER JOIN osc_physrisk_model.hazard_indicator hi ON hi.hazard_id = haz.core_id
WHERE haz.core_name_short = 'Riverine Inundation' -- more likely written as WHERE haz.core_id = '63ed7943-c4c4-43ea-abd2-86bb1997a094'
;

-- VIEW COASTAL INUNDATION HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk_model.hazard haz INNER JOIN osc_physrisk_model.hazard_indicator hi ON hi.hazard_id = haz.core_id
WHERE haz.core_id = '28a095cd-4cde-40a1-90d9-cbb0ca673c06'
;

-- VIEW CHRONIC HEAT HAZARD INDICATORS
SELECT	*
FROM
	 osc_physrisk_model.hazard haz INNER JOIN osc_physrisk_model.hazard_indicator hi ON hi.hazard_id = haz.core_id
WHERE haz.core_id = 'd08db675-ee1e-48fe-b9e1-b0da27de8f2b'
;

-- SAMPLE core_checksum UPDATE
--UPDATE osc_physrisk_model.scenario
--	SET core_checksum = md5(concat('Unknown', 'Unknown', 'Unknown', 'Unknown')) WHERE scenario_core_id = -1
--;

-- SELECT DIFFERENT ASSET TYPES
SELECT b.core_name_short as "Asset Class", a.core_name_short as "Asset Type", a.core_description_full as "Asset Type Description", b.core_tags as "Asset Class Tags", a.core_tags as "Asset Type Tags" FROM osc_physrisk_asset.asset_type a INNER JOIN osc_physrisk_asset.asset_class b ON a.asset_class_id = b.core_id
WHERE b.core_tags -> 'naics' @>  '45'
--WHERE b.core_tags ->> 'oed:occupancy:oed_code' = '1100'
ORDER BY b.core_name_short ASC
;

SELECT * from osc_physrisk_asset.generic_asset; -- NOTICE THESE ARE THE GENERIC ASSET COLUMNS AND ALL ASSETS ARE RETURNED
SELECT core_name_full, value_loan, value_ltv from osc_physrisk_asset.asset_realestate; -- NOTICE THE COLUMNS INCLUDE RE-SPECIFIC FIELDS AND ONLY RE ASSETS ARE RETURNED
SELECT core_name_full, production, capacity, availability_rate from osc_physrisk_asset.asset_powergeneratingutility; -- NOTICE THE COLUMNS INCLUDE UTILITY-SPECIFIC FIELDS AND ONLY UTILITY ASSETS ARE RETURNED

-- WE CAN ALSO DO A JOIN BY ASSET CLASS TO FILTER THE RESULTS
SELECT * from osc_physrisk_asset.generic_asset a INNER JOIN osc_physrisk_asset.asset_class b ON a.core_id = b.core_id
WHERE b.core_name_short LIKE '%Utility%'
; -- NOTICE ONLY UTILITY ROW IS RETURNED
