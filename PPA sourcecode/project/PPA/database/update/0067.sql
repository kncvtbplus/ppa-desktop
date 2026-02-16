ALTER TABLE "data_source" ADD "selected_row_count" INT NOT NULL DEFAULT 0;

INSERT INTO "_database_version" ("version") VALUES (67);

