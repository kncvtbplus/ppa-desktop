ALTER TABLE "user" ADD "password_reset_token" VARCHAR;

INSERT INTO "_database_version" ("version") VALUES (149);

