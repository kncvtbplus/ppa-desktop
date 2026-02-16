ALTER TABLE "data_source" ADD "weight_column_name" VARCHAR(1000) NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (71);

