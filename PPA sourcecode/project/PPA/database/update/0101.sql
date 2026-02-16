TRUNCATE "metric" CASCADE;
ALTER TABLE "metric" ADD "data_source_id" INT NOT NULL;
ALTER TABLE "metric" ADD FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (101);

