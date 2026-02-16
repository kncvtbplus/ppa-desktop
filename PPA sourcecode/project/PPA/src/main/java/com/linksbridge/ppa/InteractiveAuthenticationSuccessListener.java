package com.linksbridge.ppa;

import org.jboss.logging.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationListener;
import org.springframework.security.authentication.event.InteractiveAuthenticationSuccessEvent;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.linksbridge.ppa.model.User;
import com.linksbridge.ppa.repository.UserRepository;

@Component
public class InteractiveAuthenticationSuccessListener implements ApplicationListener<InteractiveAuthenticationSuccessEvent>
{
	private static final Logger LOGGER = Logger.getLogger(InteractiveAuthenticationSuccessListener.class);
	
	@Autowired
	private UserRepository userRepository;
	
	@Override
	@Transactional
	public void onApplicationEvent(InteractiveAuthenticationSuccessEvent event)
	{
		// get user
		
		String userName = event.getAuthentication().getName();
		User user = userRepository.findByUsername(userName);
		
		// set logged marker
		
		if (user != null)
		{
			user.setLogged(true);
			
		}
		
		LOGGER.info("User login. Username=" + userName);
		
	}
	
}

