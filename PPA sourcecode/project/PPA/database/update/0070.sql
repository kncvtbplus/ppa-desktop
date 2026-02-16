ALTER TABLE "data_source" ADD "weight_multiplier" INT NOT NULL DEFAULT 1;

INSERT INTO "_database_version" ("version") VALUES (70);

