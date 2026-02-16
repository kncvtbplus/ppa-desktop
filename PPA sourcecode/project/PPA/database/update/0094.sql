ALTER TABLE "file" DROP CONSTRAINT "file_user_id_fkey";
ALTER TABLE "file" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (94);

