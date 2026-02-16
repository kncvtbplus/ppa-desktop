CREATE TABLE "account"
(
"id" SERIAL NOT NULL,
"name" VARCHAR,
PRIMARY KEY ("id")
)
;

INSERT INTO "account"
SELECT "id", "username"
FROM "user"
;

ALTER TABLE "user" ADD "account_id" INT;
UPDATE "user" SET "account_id" = "id";
ALTER TABLE "user" ALTER "account_id" SET NOT NULL;
ALTER TABLE "user" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");

ALTER TABLE "ppa" ADD "account_id" INT;
UPDATE "ppa" SET "account_id" = "user_id";
ALTER TABLE "ppa" ALTER "account_id" SET NOT NULL;
ALTER TABLE "ppa" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");
ALTER TABLE "ppa" DROP CONSTRAINT "ppa_user_id_fkey";
ALTER TABLE "ppa" DROP "user_id";

INSERT INTO "_database_version" ("version") VALUES (127);

