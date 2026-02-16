ALTER TABLE "user" RENAME "session_id" TO "remote_address";

INSERT INTO "_database_version" ("version") VALUES (90);

