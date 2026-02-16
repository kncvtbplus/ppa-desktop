CREATE TABLE "user_file_content"
(
"id" SERIAL,
"user_file_id" INT NOT NULL,
"row_number" INT NOT NULL,
"column_name" VARCHAR NOT NULL,
"value" VARCHAR NOT NULL,
PRIMARY KEY ("id"),
FOREIGN KEY ("user_file_id") REFERENCES "user_file" ("id"),
UNIQUE ("user_file_id", "row_number", "column_name")
)
; 

INSERT INTO "_database_version" ("version") VALUES (133);

