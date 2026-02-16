ALTER TABLE "data_source" RENAME "available_ppa_sector_mapping_value_combinations" TO "available_ppa_sector_mapping_value_combination_frequencies";

INSERT INTO "_database_version" ("version") VALUES (34);

