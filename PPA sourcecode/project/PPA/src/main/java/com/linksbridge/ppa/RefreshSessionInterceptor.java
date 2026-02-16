package com.linksbridge.ppa;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.servlet.HandlerInterceptor;

import com.linksbridge.ppa.model.User;
import com.linksbridge.ppa.repository.UserRepository;

public class RefreshSessionInterceptor implements HandlerInterceptor
{
	// repositories
	
	@Autowired
	private UserRepository userRepository;
	
	@Override
	@Transactional
	public boolean preHandle(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, Object handler) throws Exception
	{
		// get authentication
		
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		
		if (!(authentication instanceof AnonymousAuthenticationToken))
		{
			// get user
			
		    String userName = authentication.getName();
			User user = userRepository.findByUsername(userName);
			
			// set time markers
			
			if (user != null)
			{
				user.setLastActivity(DateTime.now(DateTimeZone.UTC));
				
			}
			
		}
		
		return true;
		
	}

}
