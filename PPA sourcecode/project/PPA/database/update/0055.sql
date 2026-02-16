DELETE FROM "ppa_sector";

ALTER TABLE "ppa_sector" RENAME "user_id" TO "ppa_id";
ALTER TABLE "ppa_sector" DROP CONSTRAINT "ppa_sector_user_id_fkey";
ALTER TABLE "ppa_sector" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (55);

