DELETE FROM "metric";

ALTER TABLE "metric" ALTER "type" SET DEFAULT 'variable';

ALTER SEQUENCE "metric_id_seq" RESTART WITH 1;

INSERT INTO "metric" ("name", "type") VALUES
('Facility Type', 'domain'),
('Health Sector', 'domain'),
('Region', 'region')
;

INSERT INTO "metric" ("name") VALUES
('Number of Facilities'),
('Care Seeking'),
('Diagnostic Availability 1'),
('Diagnostic Availability 2'),
('Diagnostic Availability 3'),
('Diagnostic Availability 4'),
('Treatment Availability 1'),
('Treatment Availability 2'),
('Treatment Availability 3'),
('Treatment Availability 4'),
('Notification Location'),
('Treatment Location'),
('Treatment Outcome')
;

INSERT INTO "_database_version" ("version") VALUES (28);

