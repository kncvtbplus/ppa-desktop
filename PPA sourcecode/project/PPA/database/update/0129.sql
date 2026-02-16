ALTER TABLE "user_file" ADD UNIQUE ("account_id", "file_name");

INSERT INTO "_database_version" ("version") VALUES (129);

