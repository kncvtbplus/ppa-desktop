ALTER TABLE "user_metric_data_source" RENAME TO "ppa_metric_data_source";

ALTER TABLE "ppa_metric_data_source" RENAME "user_metric_id" TO "ppa_metric_id";

INSERT INTO "_database_version" ("version") VALUES (60);

