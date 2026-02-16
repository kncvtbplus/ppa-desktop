ALTER TABLE "ppa_metric" RENAME TO "metric";
ALTER TABLE "metric" RENAME "metric_id" TO "metric_typ_id";


INSERT INTO "_database_version" ("version") VALUES (99);

