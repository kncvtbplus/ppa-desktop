ALTER TABLE "account_user" DROP CONSTRAINT account_user_pkey;

ALTER TABLE "account_user" ADD "id" SERIAL NOT NULL;

ALTER TABLE "account_user" ADD PRIMARY KEY ("id");

ALTER TABLE "account_user" ADD UNIQUE ("account_id", "user_id");

INSERT INTO "_database_version" ("version") VALUES (157);

