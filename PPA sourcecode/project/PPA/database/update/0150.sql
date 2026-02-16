ALTER TABLE "user" ADD "password_reset_token_created" TIMESTAMP WITH TIME ZONE;

INSERT INTO "_database_version" ("version") VALUES (150);

