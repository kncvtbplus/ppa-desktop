package com.linksbridge.ppa.user;

import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.transaction.annotation.Transactional;

/**
 * @author ekiras
 */

@Transactional
public class MyUserDetails extends User
{
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	public MyUserDetails(String username, String password, Collection<? extends GrantedAuthority> authorities)
	{
		super(username, password, authorities);
		
	}

}

