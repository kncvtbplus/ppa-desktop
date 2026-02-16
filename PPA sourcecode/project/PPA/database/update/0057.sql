DELETE FROM "output";

ALTER TABLE "output" RENAME "user_id" TO "ppa_id";
ALTER TABLE "output" DROP CONSTRAINT "output_user_id_fkey";
ALTER TABLE "output" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (57);

