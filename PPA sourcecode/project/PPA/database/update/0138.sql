ALTER TABLE "user" ADD "logged" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (138);

