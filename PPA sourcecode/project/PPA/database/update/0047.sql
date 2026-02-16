ALTER TABLE "metric" ADD "r_name" VARCHAR(1000) NOT NULL DEFAULT '';

UPDATE "metric" SET "r_name" = 'Facility.Type' WHERE "id" = 1;
UPDATE "metric" SET "r_name" = 'Facility.Sector' WHERE "id" = 2;
UPDATE "metric" SET "r_name" = 'Region' WHERE "id" = 3;
UPDATE "metric" SET "r_name" = 'N.Facilities' WHERE "id" = 4;
UPDATE "metric" SET "r_name" = 'Care.Seeking' WHERE "id" = 5;
UPDATE "metric" SET "r_name" = 'Dx.Availability.1' WHERE "id" = 6;
UPDATE "metric" SET "r_name" = 'Dx.Availability.2' WHERE "id" = 7;
UPDATE "metric" SET "r_name" = 'Dx.Availability.3' WHERE "id" = 8;
UPDATE "metric" SET "r_name" = 'Dx.Availability.4' WHERE "id" = 9;
UPDATE "metric" SET "r_name" = 'Tx.Availability.1' WHERE "id" = 10;
UPDATE "metric" SET "r_name" = 'Tx.Availability.2' WHERE "id" = 11;
UPDATE "metric" SET "r_name" = 'Tx.Availability.3' WHERE "id" = 12;
UPDATE "metric" SET "r_name" = 'Tx.Availability.4' WHERE "id" = 13;
UPDATE "metric" SET "r_name" = 'Notification.Location' WHERE "id" = 14;
UPDATE "metric" SET "r_name" = 'Tx.Location' WHERE "id" = 15;
UPDATE "metric" SET "r_name" = 'Tx.Outcome' WHERE "id" = 16;

INSERT INTO "_database_version" ("version") VALUES (47);

