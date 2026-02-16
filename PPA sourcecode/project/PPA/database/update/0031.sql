ALTER TABLE "data_source" ADD "column_names" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (31);

