ALTER TABLE "invitation" ADD "administrator" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (146);

