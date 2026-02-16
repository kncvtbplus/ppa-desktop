ALTER TABLE "metric" ALTER COLUMN "data_source_id" DROP NOT NULL;

INSERT INTO "_database_version" ("version") VALUES (110);

