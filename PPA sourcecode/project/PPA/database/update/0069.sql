UPDATE "metric" SET "subtype" = 'service' WHERE "name" in ('Diagnostic Availability 1', 'Diagnostic Availability 2', 'Diagnostic Availability 3', 'Diagnostic Availability 4', 'Treatment Availability 1', 'Treatment Availability 2', 'Treatment Availability 3', 'Treatment Availability 4');

INSERT INTO "_database_version" ("version") VALUES (69);

