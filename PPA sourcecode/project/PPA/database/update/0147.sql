ALTER TABLE "invitation" ADD "account" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (147);

