ALTER TABLE "account_user" ADD FOREIGN KEY ("selected_ppa_id") REFERENCES "ppa" ("id");
 
INSERT INTO "_database_version" ("version") VALUES (162);

