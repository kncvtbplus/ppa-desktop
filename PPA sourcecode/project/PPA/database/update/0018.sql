ALTER TABLE "metric" ADD "type" VARCHAR(1000) NOT NULL DEFAULT 'domain';
UPDATE "metric" SET "type" = 'variable';

INSERT INTO "metric" ("name", "type") VALUES
('Facility Type', 'domain'),
('Health Sector', 'domain'),
('Region', 'region')
;

INSERT INTO "_database_version" ("version") VALUES (18);

