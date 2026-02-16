ALTER TABLE "data_source" ADD "facility_type_column_name" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "health_sector_column_name" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (105);

