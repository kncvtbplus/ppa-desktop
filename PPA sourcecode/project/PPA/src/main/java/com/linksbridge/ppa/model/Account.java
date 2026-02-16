package com.linksbridge.ppa.model;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.OneToMany;
import javax.persistence.OrderBy;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

@Entity
@Table(name = "account", uniqueConstraints = @UniqueConstraint(columnNames = {"name"}))
public class Account
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@Column(name = "name", nullable = false)
	private String name = "";

	@Column(name = "demo", nullable = false)
	private boolean demo = false;

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "account")
	@OrderBy("id ASC")
	private Set<Invitation> invitations = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "account")
	@OrderBy("id ASC")
	private Set<UserFile> userFiles = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "account")
	@OrderBy("id ASC")
	private Set<Ppa> ppas = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "account")
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

	public String getName()
	{
		return name;
	}

	public void setName(String name)
	{
		this.name = name;
	}

	public boolean getDemo()
	{
		return demo;
	}

	public void setDemo(boolean demo)
	{
		this.demo = demo;
	}

	public Set<Invitation> getInvitations()
	{
		return invitations;
	}

	public void setInvitations(Set<Invitation> invitations)
	{
		this.invitations = invitations;
	}

	public void addInvitation(Invitation invitation)
	{
		invitations.add(invitation);
		invitation.setAccount(this);
		
	}

	public void removeInvitation(Invitation invitation)
	{
		invitations.remove(invitation);
		invitation.setAccount(null);
		
	}

	public Set<UserFile> getUserFiles()
	{
		return userFiles;
	}

	public void setUserFiles(Set<UserFile> userFiles)
	{
		this.userFiles = userFiles;
	}

	public void addUserFile(UserFile userFile)
	{
		userFiles.add(userFile);
		userFile.setAccount(this);
		
	}

	public void removeUserFile(UserFile userFile)
	{
		userFiles.remove(userFile);
		userFile.setAccount(null);
		
	}

	public Set<Ppa> getPpas()
	{
		return ppas;
	}

	public void setPpas(Set<Ppa> ppas)
	{
		this.ppas = ppas;
	}

	public void addPpa(Ppa ppa)
	{
		ppas.add(ppa);
		ppa.setAccount(this);
		
	}

	public void removePpa(Ppa ppa)
	{
		ppas.remove(ppa);
		ppa.setAccount(null);
		
	}

	public Set<AccountUserAssociation> getAccountUserAssociations()
	{
		return accountUserAssociations;
	}

	public void setAccountUserAssociations(Set<AccountUserAssociation> accountUserAssociations)
	{
		this.accountUserAssociations = accountUserAssociations;
	}
	
	public void addAccountUserAssociation(User user, AccountUserAssociation accountUserAssociation)
	{
		accountUserAssociations.add(accountUserAssociation);
		accountUserAssociation.setAccount(this);
		
		user.getAccountUserAssociations().add(accountUserAssociation);
		accountUserAssociation.setUser(user);
		
		// set user selected account if this is the only account user is assiciated with
		
		if (user.getAccountUserAssociations().size() == 1)
		{
			user.setSelectedAccount(new ArrayList<AccountUserAssociation>(user.getAccountUserAssociations()).get(0).getAccount());
			
		}
		
	}

	public void removeAccountUserAssociation(AccountUserAssociation accountUserAssociation)
	{
		accountUserAssociations.remove(accountUserAssociation);
		accountUserAssociation.setAccount(null);
		
		accountUserAssociation.getUser().getAccountUserAssociations().remove(accountUserAssociation);
		accountUserAssociation.setUser(null);
		
	}

}

