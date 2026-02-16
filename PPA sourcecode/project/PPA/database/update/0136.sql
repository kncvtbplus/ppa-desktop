ALTER TABLE "user_file_value" DROP CONSTRAINT "user_file_content_user_file_id_fkey";
ALTER TABLE "user_file_value" ADD FOREIGN KEY ("user_file_id") REFERENCES "user_file" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (136);

