ALTER TABLE "account_user" ADD "owner" BOOLEAN NOT NULL DEFAULT false;
 
INSERT INTO "_database_version" ("version") VALUES (164);

