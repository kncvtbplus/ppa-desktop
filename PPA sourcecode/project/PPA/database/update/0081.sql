ALTER TABLE "user" ADD COLUMN "email" VARCHAR(1000);

INSERT INTO "_database_version" ("version") VALUES (81);

