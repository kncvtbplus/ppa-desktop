package com.linksbridge.ppa.user;

import java.util.HashSet;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.transaction.annotation.Transactional;

import com.linksbridge.ppa.model.User;
import com.linksbridge.ppa.model.UserRole;
import com.linksbridge.ppa.repository.UserRepository;

/**
 * @author ekiras
 */

@Transactional
public class MyUserDetailsService implements UserDetailsService
{
	private static final Logger logger = LoggerFactory.getLogger(MyUserDetailsService.class);
	
	public static final String USER_DISABLED_MESSAGE = "User is disabled.";
	
	@Autowired
	private UserRepository userRepository;

	// session timeout
	
	@Value("${server.servlet.session.timeout}")
	private int sessionTimeout;
	
	public MyUserDetailsService(UserRepository userRepository)
	{
		this.userRepository = userRepository;
		
	}

	@Override
	public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException
	{
		User user = userRepository.findByUsername(username);
		
		if (user == null)
		{
			logger.debug("User not found with the provided username: " + username);
			throw new UsernameNotFoundException("User not found.");
			
		}
		
		if (!user.getEnabled())
		{
			logger.debug("User account is disabled by administrator: " + username);
			throw new DisabledException(USER_DISABLED_MESSAGE);
			
		}
		
		// return user
		
		logger.debug("user from username " + user.toString());
		
		return new MyUserDetails(user.getUsername(), user.getPassword(), getAuthorities(user));
		
	}
	
	/**
	 * Gets user authorities.
	 * Only one logged admin is allowed per account.
	 * 
	 * @param user
	 * @return
	 */
	private Set<GrantedAuthority> getAuthorities(User user)
	{
		Set<GrantedAuthority> authorities = new HashSet<GrantedAuthority>();
		
		for (UserRole userRole : user.getUserRoles())
		{
			GrantedAuthority grantedAuthority = new SimpleGrantedAuthority(userRole.getRole());
			
			authorities.add(grantedAuthority);
			
		}
		
		logger.debug("user authorities are " + authorities.toString());
		
		return authorities;
		
	}

}

