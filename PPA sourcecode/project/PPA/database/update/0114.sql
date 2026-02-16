ALTER TABLE "metric" DROP CONSTRAINT "metric_data_source_id_fkey";
ALTER TABLE "metric" ADD FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE SET NULL;

INSERT INTO "_database_version" ("version") VALUES (114);

