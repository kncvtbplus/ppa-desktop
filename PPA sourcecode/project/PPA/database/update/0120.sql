ALTER TABLE "metric_type" RENAME "columnValueFilter" TO "column_value_filter";

INSERT INTO "_database_version" ("version") VALUES (120);

