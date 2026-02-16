package com.linksbridge.ppa.model;

import java.util.HashSet;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.OrderBy;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.persistence.UniqueConstraint;

import org.hibernate.annotations.Type;
import org.joda.time.DateTime;

@Entity
@Table(name = "user", uniqueConstraints = @UniqueConstraint(columnNames = {"username"}))
public class User
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "selected_account_id")
	private Account selectedAccount;
	
	@Column(name = "name", nullable = false)
	private String name = "";

	@Column(name = "email", nullable = false)
	private String email = "";

	@Column(name = "username", nullable = false)
	private String username = "";

	@Column(name = "password", nullable = false)
	private String password = "";

	@Column(name = "enabled", nullable = false)
	private boolean enabled = false;

	@Column(name = "remote_address")
	private String remoteAddress;

	@Column(name = "recent_login")
	private Long recentLogin;

	@Column(name = "last_activity")
	@Temporal(TemporalType.TIMESTAMP)
	@Type(type = "org.jadira.usertype.dateandtime.joda.PersistentDateTime")
	private DateTime lastActivity;

	@Column(name = "logged")
	private boolean logged = false;

	@Column(name = "selected_ppa_id")
	private Long selectedPpaId;

	@Column(name = "navigation_page", nullable = false)
	private String navigationPage = "";

	@Column(name = "password_reset_token")
	private String resetPasswordToken;

	@Column(name = "password_reset_token_created")
	@Temporal(TemporalType.TIMESTAMP)
	@Type(type = "org.jadira.usertype.dateandtime.joda.PersistentDateTime")
	private DateTime resetPasswordTokenCreated;

	@Column(name = "registration_token")
	private String registerUserToken;

	@Column(name = "registration_token_created")
	@Temporal(TemporalType.TIMESTAMP)
	@Type(type = "org.jadira.usertype.dateandtime.joda.PersistentDateTime")
	private DateTime registerUserTokenCreated;

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "user")
	@OrderBy("id ASC")
	private Set<UserRole> userRoles = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "user")
	@OrderBy("id ASC")
	private Set<AccountUserAssociation> accountUserAssociations = new HashSet<>();

	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public Account getSelectedAccount()
	{
		return selectedAccount;
	}

	public void setSelectedAccount(Account selectedAccount)
	{
		this.selectedAccount = selectedAccount;
	}

	public String getName()
	{
		return name;
	}

	public void setName(String name)
	{
		this.name = name;
	}

	public String getEmail()
	{
		return email;
	}

	public void setEmail(String email)
	{
		this.email = email;
	}

	public String getUsername()
	{
		return username;
	}

	public void setUsername(String username)
	{
		this.username = username;
	}

	public String getPassword()
	{
		return password;
	}

	public void setPassword(String password)
	{
		this.password = password;
	}

	public boolean getEnabled()
	{
		return enabled;
	}

	public void setEnabled(boolean enabled)
	{
		this.enabled = enabled;
	}

	public String getRemoteAddress()
	{
		return remoteAddress;
	}

	public void setRemoteAddress(String remoteAddress)
	{
		this.remoteAddress = remoteAddress;
	}

	public DateTime getLastActivity()
	{
		return lastActivity;
	}

	public void setLastActivity(DateTime lastActivity)
	{
		this.lastActivity = lastActivity;
	}

	public boolean getLogged()
	{
		return logged;
	}

	public void setLogged(boolean logged)
	{
		this.logged = logged;
	}

	public Long getRecentLogin()
	{
		return recentLogin;
	}

	public void setRecentLogin(Long recentLogin)
	{
		this.recentLogin = recentLogin;
	}

	public Long getSelectedPpaId()
	{
		return selectedPpaId;
	}

	public void setSelectedPpaId(Long selectedPpaId)
	{
		this.selectedPpaId = selectedPpaId;
	}

	public String getNavigationPage()
	{
		return navigationPage;
	}

	public void setNavigationPage(String navigationPage)
	{
		this.navigationPage = navigationPage;
	}

	public String getResetPasswordToken()
	{
		return resetPasswordToken;
	}

	public void setResetPasswordToken(String resetPasswordToken)
	{
		this.resetPasswordToken = resetPasswordToken;
	}

	public DateTime getResetPasswordTokenCreated()
	{
		return resetPasswordTokenCreated;
	}

	public void setResetPasswordTokenCreated(DateTime resetPasswordTokenCreated)
	{
		this.resetPasswordTokenCreated = resetPasswordTokenCreated;
	}

	public String getRegisterUserToken()
	{
		return registerUserToken;
	}

	public void setRegisterUserToken(String registerUserToken)
	{
		this.registerUserToken = registerUserToken;
	}

	public DateTime getRegisterUserTokenCreated()
	{
		return registerUserTokenCreated;
	}

	public void setRegisterUserTokenCreated(DateTime registerUserTokenCreated)
	{
		this.registerUserTokenCreated = registerUserTokenCreated;
	}

	public Set<UserRole> getUserRoles()
	{
		return userRoles;
	}

	public void setUserRoles(Set<UserRole> userRoles)
	{
		this.userRoles = userRoles;
	}

	public void addUserRole(UserRole userRole)
	{
		userRoles.add(userRole);
		userRole.setUser(this);
		
	}

	public void removeUserRole(UserRole userRole)
	{
		userRoles.remove(userRole);
		userRole.setUser(null);
		
	}

	public Set<AccountUserAssociation> getAccountUserAssociations()
	{
		return accountUserAssociations;
	}

	public void setAccountUserAssociations(Set<AccountUserAssociation> accountUserAssociations)
	{
		this.accountUserAssociations = accountUserAssociations;
	}
	
	public void addAccountUserAssociation(Account account, boolean administrator)
	{
		AccountUserAssociation accountUserAssociation = new AccountUserAssociation();
		accountUserAssociation.setAdministrator(administrator);
		
		accountUserAssociations.add(accountUserAssociation);
		account.getAccountUserAssociations().add(accountUserAssociation);
		
	}

	public void removeAccountUserAssociation(AccountUserAssociation accountUserAssociation)
	{
		accountUserAssociations.remove(accountUserAssociation);
		accountUserAssociation.getAccount().getAccountUserAssociations().remove(accountUserAssociation);
		
	}

}

