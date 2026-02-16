ALTER TABLE "ppa_metric" ADD "selected" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (86);

