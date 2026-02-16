ALTER TABLE "data_source" DROP "info";

ALTER TABLE "user_metric_data_source" DROP "selected_column_values";

ALTER TABLE "user_metric_data_source" ADD "available_column_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "user_metric_data_source" ADD "selected_column_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (30);

