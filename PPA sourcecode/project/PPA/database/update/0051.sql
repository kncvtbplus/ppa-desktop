ALTER TABLE "data_source" DROP "subset_column_1";
ALTER TABLE "data_source" DROP "subset_column_1_values";
ALTER TABLE "data_source" DROP "subset_column_1_selected_values";
ALTER TABLE "data_source" DROP "subset_column_2";
ALTER TABLE "data_source" DROP "subset_column_2_values";
ALTER TABLE "data_source" DROP "subset_column_2_selected_values";

INSERT INTO "_database_version" ("version") VALUES (51);

