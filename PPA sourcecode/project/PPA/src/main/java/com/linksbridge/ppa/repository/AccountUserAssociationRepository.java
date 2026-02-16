package com.linksbridge.ppa.repository;

import com.linksbridge.ppa.model.Account;
import com.linksbridge.ppa.model.AccountUserAssociation;
import com.linksbridge.ppa.model.User;

public interface AccountUserAssociationRepository extends CustomJpaRepository<AccountUserAssociation, Long>
{
	boolean existsByAccountAndUser(Account account, User user);

	AccountUserAssociation findByAccountAndUser(Account account, User user);

}

