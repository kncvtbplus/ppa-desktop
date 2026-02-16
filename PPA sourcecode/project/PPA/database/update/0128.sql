ALTER TABLE "user_file" ADD "account_id" INT;
UPDATE "user_file" SET "account_id" = "user_id";
ALTER TABLE "user_file" ALTER "account_id" SET NOT NULL;
ALTER TABLE "user_file" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");
ALTER TABLE "user_file" DROP CONSTRAINT "file_user_id_fkey";
ALTER TABLE "user_file" DROP "user_id";

INSERT INTO "_database_version" ("version") VALUES (128);

