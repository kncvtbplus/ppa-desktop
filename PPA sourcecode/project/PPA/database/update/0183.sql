-- Guest user & Public account for login-skip functionality in local/desktop mode.
-- The guest user has ROLE_USER only (no admin) so it can use public PPAs but
-- cannot manage accounts or invite users.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
    v_account_id INT;
    v_user_id    INT;
BEGIN
    -- Create "Public" account (shared space for PPAs available without login)
    INSERT INTO "account" ("name", "demo")
    VALUES ('Public', FALSE)
    ON CONFLICT ("name") DO NOTHING;

    SELECT id INTO v_account_id FROM "account" WHERE name = 'Public';

    -- Create guest user with a random password (never used for direct login)
    INSERT INTO "user" ("username", "password", "enabled", "email", "name", "selected_account_id", "navigation_page")
    VALUES (
        'guest@ppa-desktop',
        crypt(gen_random_uuid()::text, gen_salt('bf')),
        TRUE,
        'guest@ppa-desktop',
        'Guest',
        v_account_id,
        ''
    )
    ON CONFLICT ("username") DO UPDATE
        SET "enabled" = TRUE,
            "selected_account_id" = v_account_id;

    SELECT id INTO v_user_id FROM "user" WHERE username = 'guest@ppa-desktop';

    -- Assign ROLE_USER only (no ROLE_ADMIN)
    INSERT INTO "user_role" ("user_id", "role")
    VALUES (v_user_id, 'ROLE_USER')
    ON CONFLICT DO NOTHING;

    -- Link guest to the Public account (non-admin, non-owner)
    INSERT INTO "account_user" ("account_id", "user_id", "administrator", "owner")
    VALUES (v_account_id, v_user_id, FALSE, FALSE)
    ON CONFLICT ("account_id", "user_id") DO NOTHING;
END
$$;

INSERT INTO "_database_version" ("version") VALUES (183);
