ALTER TABLE "ppa_sector_level" ALTER "level" TYPE VARCHAR(1000);
ALTER TABLE "ppa_sector_level" ALTER "level" SET NOT NULL;
ALTER TABLE "ppa_sector_level" ALTER "level" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (72);

