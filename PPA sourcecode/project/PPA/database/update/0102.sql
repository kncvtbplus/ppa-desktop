ALTER TABLE "metric" ADD "data_source_column_name" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "metric" ADD "column_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "metric" ADD "selected_column_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (102);

