UPDATE "user_metric_data_source" SET "data_source_column_name" = '';
ALTER TABLE "user_metric_data_source" ALTER "data_source_column_name" SET NOT NULL;
ALTER TABLE "user_metric_data_source" ALTER "data_source_column_name" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (19);

