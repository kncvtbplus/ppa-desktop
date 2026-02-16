TRUNCATE TABLE "data_source" CASCADE;
ALTER TABLE "data_source" ADD "file_id" INT NOT NULL;
ALTER TABLE "data_source" DROP "s3_file_name";
ALTER TABLE "data_source" DROP "file_name";
ALTER TABLE "data_source" DROP "column_names";
ALTER TABLE "data_source" ADD FOREIGN KEY ("file_id") REFERENCES "file" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (96);

