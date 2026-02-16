ALTER TABLE "invitation" ADD "email" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (145);

