package com.linksbridge.ppa.repository;

import java.util.List;

import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.linksbridge.ppa.model.Account;
import com.linksbridge.ppa.model.User;

public interface UserRepository extends CustomJpaRepository<User, Long>
{
	boolean existsByUsername(String username);

	User findByUsername(String username);

	List<User> findByIdIn(List<Long> userIds);

	List<User> findAllByUsername(String username);

	List<User> findAllBySelectedAccountId(Long id, Sort by);

	List<User> findByResetPasswordToken(String token);

	@Query("SELECT user FROM User user WHERE user in (SELECT accountUserAssociation.user FROM AccountUserAssociation accountUserAssociation WHERE accountUserAssociation.account = :account)")
	List<User> getAccountUsers(@Param("account") Account account);

//	@Query("SELECT user FROM User user WHERE user <> :user AND user.logged = true AND user in (SELECT accountUserAssociation.user FROM AccountUserAssociation accountUserAssociation WHERE accountUserAssociation.account = :account AND accountUserAssociation.administrator = true)")
//	List<User> getAccountOtherLoggedAdministrators(@Param("user") User user, @Param("account") Account account);

// NWL
	@Query(
    "SELECT other_user FROM User AS other_user " +
    "JOIN AccountUserAssociation AS my_au ON my_au.user = :myself " +
    "JOIN AccountUserAssociation AS other_au ON other_au.user = other_user " +
    "WHERE other_user <> :myself " +
    // "AND u.selected_account_id = au.account_id "
    "AND other_user.logged = true " +
    "AND other_au.administrator = true " +
    "AND other_au.selectedPpa = my_au.selectedPpa " +
    "AND other_user.selectedAccount = :#{#myself.selectedAccount} " +
    "AND other_au.account = :#{#myself.selectedAccount} "
	)
	List<User> getPpaOtherLoggedAdministrators(@Param("myself") User user);

	User findByRegisterUserToken(String token);

	User findByEmail(String email);
	
}

