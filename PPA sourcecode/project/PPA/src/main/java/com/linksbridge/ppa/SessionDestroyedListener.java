package com.linksbridge.ppa;

import org.jboss.logging.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationListener;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.session.SessionDestroyedEvent;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.linksbridge.ppa.model.User;
import com.linksbridge.ppa.repository.UserRepository;

@Component
public class SessionDestroyedListener implements ApplicationListener<SessionDestroyedEvent>
{
	private static final Logger LOGGER = Logger.getLogger(InteractiveAuthenticationSuccessListener.class);
	
	@Autowired
	private UserRepository userRepository;
	
	@Override
	@Transactional
	public void onApplicationEvent(SessionDestroyedEvent event)
	{
		for (SecurityContext securityContext : event.getSecurityContexts())
		{
			// get user
			
			String userName = securityContext.getAuthentication().getName();
			User user = userRepository.findByUsername(userName);
			
			// set logged marker
			
			if (user != null)
			{
				user.setLogged(false);
				
			}
			
			LOGGER.info("User logout. Username=" + userName);
			
		}
		
	}
		
}

