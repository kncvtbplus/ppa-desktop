ALTER TABLE "data_source" ADD "subset_column1_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_value_frequencies" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (66);

