UPDATE "metric" SET "type" = 'facilityType' WHERE "subtype" = 'facilityType';
UPDATE "metric" SET "type" = 'healthSector' WHERE "subtype" = 'healthSector';

INSERT INTO "_database_version" ("version") VALUES (68);

