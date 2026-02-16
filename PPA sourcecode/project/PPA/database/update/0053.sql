DELETE FROM "data_source";
ALTER TABLE "data_source" RENAME "user_id" TO "ppa_id";
ALTER TABLE "data_source" DROP CONSTRAINT "data_source_user_id_fkey";
ALTER TABLE "data_source" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (53);

