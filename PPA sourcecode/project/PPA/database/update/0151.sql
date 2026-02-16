CREATE TABLE "account_user"
(
"account_id" INT NOT NULL,
"user_id" INT NOT NULL,
PRIMARY KEY ("account_id", "user_id")
)
;

INSERT INTO "account_user"
SELECT "account"."id", "user"."id"
FROM "user"
JOIN "account" on "account"."id" = "user"."account_id"
;

ALTER TABLE "user" DROP CONSTRAINT "user_account_id_fkey";
ALTER TABLE "user" DROP COLUMN "account_id";

INSERT INTO "_database_version" ("version") VALUES (151);

