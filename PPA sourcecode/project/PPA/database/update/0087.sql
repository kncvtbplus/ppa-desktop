ALTER TABLE "user" ADD "last_activity" TIMESTAMP NOT NULL DEFAULT NOW();

INSERT INTO "_database_version" ("version") VALUES (87);

