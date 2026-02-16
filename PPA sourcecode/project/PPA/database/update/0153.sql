UPDATE "user"
SET "selected_account_id" = "account_user"."account_id"
FROM "account_user"
WHERE "account_user"."user_id" = "user"."id"
;


ALTER TABLE "user" ALTER COLUMN "selected_account_id" SET NOT NULL;

INSERT INTO "_database_version" ("version") VALUES (153);

