ALTER TABLE "ppa" ADD "region" VARCHAR(1000) NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (58);

