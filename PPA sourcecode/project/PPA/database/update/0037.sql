ALTER TABLE "user_metric_data_source" ADD "available_column_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (37);

