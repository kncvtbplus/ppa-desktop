ALTER TABLE "user_metric_data_source" RENAME COLUMN "data_source_column" TO "data_source_column_name";

INSERT INTO "_database_version" ("version") VALUES (14);

