ALTER TABLE "data_source" ADD "subnational_unit_column_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subnational_unit_column_selected_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (106);

