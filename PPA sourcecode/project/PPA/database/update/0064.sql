ALTER TABLE "ppa_sector" DROP CONSTRAINT "ppa_sector_name_key";
ALTER TABLE "ppa_sector" ADD UNIQUE ("ppa_id", "name");

INSERT INTO "_database_version" ("version") VALUES (64);

