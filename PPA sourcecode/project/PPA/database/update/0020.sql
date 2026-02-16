ALTER TABLE "data_source" ADD "used" BOOLEAN NOT NULL DEFAULT false;

INSERT INTO "_database_version" ("version") VALUES (20);

