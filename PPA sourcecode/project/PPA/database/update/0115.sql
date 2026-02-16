ALTER TABLE "data_source" ADD "facility_type_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "health_sector_value_frequencies" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (115);

