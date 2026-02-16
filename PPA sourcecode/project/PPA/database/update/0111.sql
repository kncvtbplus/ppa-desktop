ALTER SEQUENCE "metric_id_seq" RENAME TO "metric_type_id_seq";
ALTER SEQUENCE "ppa_metric_id_seq" RENAME TO "metric_id_seq";

INSERT INTO "_database_version" ("version") VALUES (111);

