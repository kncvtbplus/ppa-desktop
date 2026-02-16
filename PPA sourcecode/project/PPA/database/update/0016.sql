DROP TABLE "data_source_column";

ALTER TABLE "data_source" ADD "column_names" VARCHAR(1000); 

INSERT INTO "_database_version" ("version") VALUES (16);

