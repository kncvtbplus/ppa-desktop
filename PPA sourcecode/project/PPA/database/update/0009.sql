CREATE TABLE "metric"
(
	"id" SERIAL NOT NULL,
	"name" VARCHAR(1000) NOT NULL,
	PRIMARY KEY ("id"),
	UNIQUE ("name")
)
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

INSERT INTO "_database_version" ("version") VALUES (9);

