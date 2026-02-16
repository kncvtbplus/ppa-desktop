ALTER TABLE "user" ALTER "selected_account_id" DROP NOT NULL;
 
INSERT INTO "_database_version" ("version") VALUES (163);

