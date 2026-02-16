ALTER TABLE "data_source" ADD "subnational_unit_column_name" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (104);

