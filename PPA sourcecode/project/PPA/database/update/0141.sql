ALTER TABLE "user" ADD "token" VARCHAR;
ALTER TABLE "user" ADD "token_created" TIMESTAMP;

INSERT INTO "_database_version" ("version") VALUES (141);

