package com.linksbridge.ppa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.linksbridge.ppa.model.Account;
import com.linksbridge.ppa.model.AccountUserAssociation;
import com.linksbridge.ppa.model.User;
import com.linksbridge.ppa.model.UserRole;
import com.linksbridge.ppa.repository.AccountRepository;
import com.linksbridge.ppa.repository.AccountUserAssociationRepository;
import com.linksbridge.ppa.repository.UserRepository;

import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Previously this component created a default "localadmin" user for
 * local installs. The new Windows installer flow expects that users
 * always self‑register, so this initializer has been turned into a
 * no‑op. The class is kept only to avoid touching other configuration.
 */
@Component
public class LocalAdminInitializer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(LocalAdminInitializer.class);

    // Default local credentials – documented in the Windows user guide
    public static final String DEFAULT_USERNAME = "localadmin@ppa-wizard";
    public static final String DEFAULT_PASSWORD = "PpaWizard123!";

    private static final String ROLE_USER = "ROLE_USER";
    private static final String ROLE_ADMIN = "ROLE_ADMIN";

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AccountRepository accountRepository;

    @Autowired
    private AccountUserAssociationRepository accountUserAssociationRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        // Intentionally left blank – users are expected to self‑register
        // through the normal registration flow. This avoids any pre‑seeded
        // accounts or demo data in local Windows installations.
        logger.info("LocalAdminInitializer: no default user created; users must self‑register.");
    }
}


