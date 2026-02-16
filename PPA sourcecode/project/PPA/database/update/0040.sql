UPDATE "data_source" SET "health_sector_column_values" = '';
ALTER TABLE "data_source" ALTER "health_sector_column_values" SET NOT NULL;
ALTER TABLE "data_source" ALTER "health_sector_column_values" SET DEFAULT '';

UPDATE "data_source" SET "facility_type_column_values" = '';
ALTER TABLE "data_source" ALTER "facility_type_column_values" SET NOT NULL;
ALTER TABLE "data_source" ALTER "facility_type_column_values" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (40);

