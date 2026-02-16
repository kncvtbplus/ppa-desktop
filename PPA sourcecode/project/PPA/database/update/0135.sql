ALTER SEQUENCE "user_file_content_id_seq" RENAME TO "user_file_value_id_seq";

INSERT INTO "_database_version" ("version") VALUES (135);

