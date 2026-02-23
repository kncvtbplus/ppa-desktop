package com.linksbridge.ppa.repository;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.linksbridge.ppa.model.Account;
import com.linksbridge.ppa.model.User;

public interface AccountRepository extends CustomJpaRepository<Account, Long>
{
	Account findByName(String name);

	List<Account> findAllByName(String name);

	@Query("SELECT account FROM Account account WHERE account in (SELECT accountUserAssociation.account FROM AccountUserAssociation accountUserAssociation WHERE accountUserAssociation.user = :user)")
	List<Account> getUserAccounts(@Param("user") User user);

	boolean existsByName(String name);

	List<Account> findAllByDemo(boolean demo);

}

