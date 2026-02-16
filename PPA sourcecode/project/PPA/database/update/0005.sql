ALTER TABLE "user" ADD "region" VARCHAR(1000) NOT NULL DEFAULT 'National';

INSERT INTO "_database_version" ("version") VALUES (5);

