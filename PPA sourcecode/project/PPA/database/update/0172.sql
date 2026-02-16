ALTER TABLE "user_file" DROP CONSTRAINT "user_file_account_id_fkey";

ALTER TABLE "user_file" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (172);

