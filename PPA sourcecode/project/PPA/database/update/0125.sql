UPDATE "metric_type" SET "r_header" = 'N.Facilities', "r_header_availability" = '', "r_header_access" = '' WHERE "id" = 4;
UPDATE "metric_type" SET "r_header" = 'Care.Seeking', "r_header_availability" = '', "r_header_access" = '' WHERE "id" = 5;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.1.Availability', "r_header_access" = 'Diagnostic.1.Access' WHERE "id" = 6;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.2.Availability', "r_header_access" = 'Diagnostic.2.Access' WHERE "id" = 7;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.3.Availability', "r_header_access" = 'Diagnostic.3.Access' WHERE "id" = 8;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.4.Availability', "r_header_access" = 'Diagnostic.4.Access' WHERE "id" = 9;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.1.Availability', "r_header_access" = 'Treatment.1.Access' WHERE "id" = 10;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.2.Availability', "r_header_access" = 'Treatment.2.Access' WHERE "id" = 11;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.3.Availability', "r_header_access" = 'Treatment.3.Access' WHERE "id" = 12;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.4.Availability', "r_header_access" = 'Treatment.4.Access' WHERE "id" = 13;

INSERT INTO "_database_version" ("version") VALUES (125);

