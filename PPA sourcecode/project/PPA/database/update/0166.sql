ALTER TABLE "user" DROP CONSTRAINT "user_selected_account_id_fkey";
ALTER TABLE "user" ADD FOREIGN KEY ("selected_account_id") REFERENCES "account" ("id") ON DELETE SET NULL;

INSERT INTO "_database_version" ("version") VALUES (166);

