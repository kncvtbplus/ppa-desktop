-- Create a demo user linked to a Namibia PPA/account so you can log in as a demo user.
-- Login:
--   Username: demo.namibia@local
--   Password: DemoNamibia123!

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
    v_ppa_id      INT;
    v_account_id  INT;
    v_user_id     INT;
BEGIN
    -- Pick one PPA for Namibia to use as the demo PPA (adjust name/ID if desired)
    SELECT id, account_id
    INTO v_ppa_id, v_account_id
    FROM ppa
    WHERE name = 'PPA Namibia New'
      AND aggregation_level = 'National'
    LIMIT 1;

    IF v_ppa_id IS NULL THEN
        RAISE EXCEPTION 'Could not find PPA Namibia New (National) to use for demo';
    END IF;

    -- Create or update the demo user
    INSERT INTO "user"
        ("username", "password", "enabled", "email", "name", "selected_account_id", "navigation_page")
    VALUES
        (
            'demo.namibia@local',
            crypt('DemoNamibia123!', gen_salt('bf')),
            TRUE,
            'demo.namibia@local',
            'Demo Namibia',
            v_account_id,
            ''
        )
    ON CONFLICT ("username") DO UPDATE
        SET
            "password"            = EXCLUDED."password",
            "enabled"             = EXCLUDED."enabled",
            "email"               = EXCLUDED."email",
            "name"                = EXCLUDED."name",
            "selected_account_id" = EXCLUDED."selected_account_id"
    RETURNING id INTO v_user_id;

    -- If user already existed and wasn't returned by INSERT (older PG versions), look it up
    IF v_user_id IS NULL THEN
        SELECT id INTO v_user_id
        FROM "user"
        WHERE username = 'demo.namibia@local';
    END IF;

    -- Link user to the Namibia account, with admin rights and selected PPA
    INSERT INTO account_user (account_id, user_id, administrator, selected_ppa_id, owner)
    VALUES (v_account_id, v_user_id, TRUE, v_ppa_id, FALSE)
    ON CONFLICT (account_id, user_id) DO UPDATE
        SET
            administrator   = TRUE,
            selected_ppa_id = EXCLUDED.selected_ppa_id;

    -- Ensure the user has ROLE_USER and ROLE_ADMIN
    INSERT INTO user_role (user_id, role)
    VALUES
        (v_user_id, 'ROLE_USER'),
        (v_user_id, 'ROLE_ADMIN')
    ON CONFLICT DO NOTHING;
END
$$;


