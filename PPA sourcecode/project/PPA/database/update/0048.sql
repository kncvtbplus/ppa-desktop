ALTER TABLE "data_source" ADD "subset_column_1" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_2" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_1_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_2_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (48);

