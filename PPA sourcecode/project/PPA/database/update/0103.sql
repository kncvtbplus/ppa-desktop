ALTER TABLE "file" RENAME TO "user_file";
ALTER TABLE "data_source" RENAME "file_id" TO "user_file_id";

INSERT INTO "_database_version" ("version") VALUES (103);

