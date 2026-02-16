ALTER TABLE "user" ADD FOREIGN KEY ("selected_account_id") REFERENCES "account" ("id");

INSERT INTO "_database_version" ("version") VALUES (154);

