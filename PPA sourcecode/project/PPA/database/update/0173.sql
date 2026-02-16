ALTER TABLE "user" ADD "registration_token" VARCHAR;
ALTER TABLE "user" ADD "registration_token_created" TIMESTAMP WITH TIME ZONE;

INSERT INTO "_database_version" ("version") VALUES (173);

