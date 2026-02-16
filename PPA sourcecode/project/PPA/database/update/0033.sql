ALTER TABLE "data_source" ADD "available_ppa_sector_mapping_value_combinations" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (33);

