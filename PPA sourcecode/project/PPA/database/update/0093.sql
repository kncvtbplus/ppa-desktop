CREATE TABLE "file"
(
"id" SERIAL PRIMARY KEY,
"user_id" INT NOT NULL,
"s3_file_name" VARCHAR NOT NULL,
"file_name" VARCHAR NOT NULL,
"column_names" TEXT NOT NULL,
FOREIGN KEY ("user_id") REFERENCES "user" ("id")
)
;

INSERT INTO "_database_version" ("version") VALUES (93);

