ALTER TABLE "user" ADD "session_id" VARCHAR;
ALTER TABLE "user" DROP "last_activity";
ALTER TABLE "user" ADD "last_activity" TIMESTAMP;

INSERT INTO "_database_version" ("version") VALUES (88);

