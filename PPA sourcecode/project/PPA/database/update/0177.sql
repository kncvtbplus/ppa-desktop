DROP TABLE "ppa_sector_default_values";

CREATE TABLE "ppa_sector_default_values"
(
	"id" SERIAL,
    "order" INTEGER NOT NULL,
    "name" VARCHAR NOT NULL,
    "editable" BOOLEAN NOT NULL,
    PRIMARY KEY ("id"),
    UNIQUE ("order")
)
;

INSERT INTO "ppa_sector_default_values"
("order", "name", "editable")
VALUES
(1, 'Public', false),
(2, 'Private', false),
(3, 'Informal Private', false),
(4, 'CUSTOM SECTOR - ENTER TEXT HERE', true)
;

INSERT INTO "_database_version" ("version") VALUES (177);

