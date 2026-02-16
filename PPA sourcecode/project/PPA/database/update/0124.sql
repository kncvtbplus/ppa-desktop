UPDATE "metric_type" SET "r_header" = 'N.Facilities', "r_header_availability" = '', "r_header_access" = '' WHERE "name" = 'Number of Facilities';
UPDATE "metric_type" SET "r_header" = 'Care.Seeking', "r_header_availability" = '', "r_header_access" = '' WHERE "name" = 'Care Seeking';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.1.Availability', "r_header_access" = 'Diagnostic.1.Access' WHERE "name" = 'Diagnostic Availability 1';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.2.Availability', "r_header_access" = 'Diagnostic.2.Access' WHERE "name" = 'Diagnostic Availability 2';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.3.Availability', "r_header_access" = 'Diagnostic.3.Access' WHERE "name" = 'Diagnostic Availability 3';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.4.Availability', "r_header_access" = 'Diagnostic.4.Access' WHERE "name" = 'Diagnostic Availability 4';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.1.Availability', "r_header_access" = 'Treatment.1.Access' WHERE "name" = 'Treatment Availability 1';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.2.Availability', "r_header_access" = 'Treatment.2.Access' WHERE "name" = 'Treatment Availability 2';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.3.Availability', "r_header_access" = 'Treatment.3.Access' WHERE "name" = 'Treatment Availability 3';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.4.Availability', "r_header_access" = 'Treatment.4.Access' WHERE "name" = 'Treatment Availability 4';

INSERT INTO "_database_version" ("version") VALUES (124);

