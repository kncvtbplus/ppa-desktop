package com.linksbridge.ppa;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.stereotype.Component;

import com.linksbridge.ppa.user.MyUserDetailsService;

@Component
public class CustomAuthenticationFailureHandler implements AuthenticationFailureHandler
{
	private static final Logger LOGGER = LoggerFactory.getLogger(CustomAuthenticationFailureHandler.class);

	@Override
	public void onAuthenticationFailure
	(
			HttpServletRequest httpServletRequest,
			HttpServletResponse httpServletResponse,
			AuthenticationException authenticationException
	) throws IOException, ServletException
	{
		LOGGER.info("Authentication Failure: " + authenticationException.getMessage());
		
		int status;
		
		if (MyUserDetailsService.USER_DISABLED_MESSAGE.equals(authenticationException.getMessage()))
		{
			// 409
			status = HttpServletResponse.SC_CONFLICT;
			
		}
		else
		{
			// 402
			status = HttpServletResponse.SC_PAYMENT_REQUIRED;
			
		}
		
		httpServletResponse.setStatus(status);

	}
	
}

