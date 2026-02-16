DELETE FROM "user_metric";

ALTER TABLE "user_metric" RENAME TO "ppa_metric";
ALTER TABLE "ppa_metric" RENAME "user_id" TO "ppa_id";
ALTER TABLE "ppa_metric" DROP CONSTRAINT "user_metric_user_id_fkey";
ALTER TABLE "ppa_metric" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (54);

