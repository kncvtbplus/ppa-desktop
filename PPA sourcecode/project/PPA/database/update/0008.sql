ALTER TABLE "data_source" ADD "type" VARCHAR(1000) NOT NULL DEFAULT 'Raw';

INSERT INTO "_database_version" ("version") VALUES (8);

