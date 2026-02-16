ALTER TABLE "data_source" ADD "subset_column_1_selected_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_2_selected_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (49);

