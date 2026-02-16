ALTER TABLE "ppa" DROP CONSTRAINT "ppa_account_id_fkey";

ALTER TABLE "ppa" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (171);

