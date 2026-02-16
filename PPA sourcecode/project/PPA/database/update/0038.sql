ALTER TABLE "metric" ADD "subtype" VARCHAR(1000);

UPDATE "metric" SET "subtype" = 'healthSector' where "name" = 'Health Sector';
UPDATE "metric" SET "subtype" = 'facilityType' where "name" = 'Facility Type';

INSERT INTO "_database_version" ("version") VALUES (38);

