ALTER TABLE "metric_type" ADD "required" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (117);

