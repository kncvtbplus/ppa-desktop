DELETE FROM "subnational_unit";

ALTER TABLE "subnational_unit" RENAME "user_id" TO "ppa_id";
ALTER TABLE "subnational_unit" DROP CONSTRAINT "subnational_unit_user_id_fkey";
ALTER TABLE "subnational_unit" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (56);

