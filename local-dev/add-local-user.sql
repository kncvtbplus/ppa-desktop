-- Create pgcrypto extension for bcrypt hashing if it doesn't exist yet
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create or update a local admin user with a known test password.
-- Username: localadmin
-- Password: Local123!

INSERT INTO "user" ("username", "password", "enabled")
VALUES (
    'localadmin',
    crypt('Local123!', gen_salt('bf')),
    TRUE
)
ON CONFLICT ("username") DO UPDATE
SET
    "password" = EXCLUDED."password",
    "enabled"  = EXCLUDED."enabled";

-- Ensure the user has both ROLE_USER and ROLE_ADMIN
WITH u AS (
    SELECT "id" FROM "user" WHERE "username" = 'localadmin'
)
INSERT INTO "user_role" ("user_id", "role")
SELECT u.id, r.role
FROM u
JOIN (VALUES ('ROLE_USER'), ('ROLE_ADMIN')) AS r(role) ON TRUE
ON CONFLICT DO NOTHING;


