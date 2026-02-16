ALTER TABLE "file" ADD UNIQUE ("user_id", "file_name");

INSERT INTO "_database_version" ("version") VALUES (95);

