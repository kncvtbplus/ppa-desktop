package com.linksbridge.ppa.model;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

@Entity
@Table(name = "account_user", uniqueConstraints = @UniqueConstraint(columnNames = {"account_id", "user_id"}))
public class AccountUserAssociation
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "account_id", nullable = false)
	private Account account;
	
	@ManyToOne
	@JoinColumn(name = "user_id", nullable = false)
	private User user;
	
	@Column(name = "owner", nullable = false)
	private boolean owner = false;

	@Column(name = "administrator", nullable = false)
	private boolean administrator = false;

	@ManyToOne
	@JoinColumn(name = "selected_ppa_id", nullable = true)
	private Ppa selectedPpa;
	
	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public Account getAccount()
	{
		return account;
	}

	public void setAccount(Account account)
	{
		this.account = account;
	}

	public User getUser()
	{
		return user;
	}

	public void setUser(User user)
	{
		this.user = user;
	}

	public boolean getOwner()
	{
		return owner;
	}

	public void setOwner(boolean owner)
	{
		this.owner = owner;
	}

	public boolean getAdministrator()
	{
		return administrator;
	}

	public void setAdministrator(boolean administrator)
	{
		this.administrator = administrator;
	}

	public Ppa getSelectedPpa()
	{
		return selectedPpa;
	}

	public void setSelectedPpa(Ppa selectedPpa)
	{
		this.selectedPpa = selectedPpa;
	}

}

