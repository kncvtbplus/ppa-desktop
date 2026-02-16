ALTER TABLE "account_user" DROP CONSTRAINT "account_user_account_id_fkey";
ALTER TABLE "account_user" DROP CONSTRAINT "account_user_user_id_fkey";
ALTER TABLE "account_user" DROP CONSTRAINT "account_user_selected_ppa_id_fkey";
 
ALTER TABLE "account_user" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON DELETE CASCADE;
ALTER TABLE "account_user" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE;
ALTER TABLE "account_user" ADD FOREIGN KEY ("selected_ppa_id") REFERENCES "ppa" ("id") ON DELETE SET NULL;

INSERT INTO "_database_version" ("version") VALUES (165);

