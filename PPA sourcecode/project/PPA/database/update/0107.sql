ALTER TABLE "data_source" RENAME "subnational_unit_column_value_frequencies" TO "subnational_unit_value_frequencies";
ALTER TABLE "data_source" RENAME "subnational_unit_column_selected_values" TO "subnational_unit_selected_values";

INSERT INTO "_database_version" ("version") VALUES (107);

