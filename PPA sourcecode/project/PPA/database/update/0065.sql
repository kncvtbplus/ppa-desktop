ALTER TABLE "data_source" ADD "subset_column1_name" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column1_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column1_selected_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_name" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_selected_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (65);

