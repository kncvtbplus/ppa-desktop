ALTER TABLE "data_source" DROP CONSTRAINT "data_source_user_id_fkey";
ALTER TABLE "data_source" ADD UNIQUE ("ppa_id", "file_id");

INSERT INTO "_database_version" ("version") VALUES (97);

