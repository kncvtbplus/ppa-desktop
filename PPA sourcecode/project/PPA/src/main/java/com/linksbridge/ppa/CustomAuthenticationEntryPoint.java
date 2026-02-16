package com.linksbridge.ppa;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

@Component
public class CustomAuthenticationEntryPoint implements AuthenticationEntryPoint
{
	private static final Logger LOGGER = LoggerFactory.getLogger(CustomAuthenticationEntryPoint.class);
	
	@Override
	public void commence
	(
			HttpServletRequest httpServletRequest,
			HttpServletResponse httpServletResponse,
			AuthenticationException authenticationException
	) throws IOException
	{
		LOGGER.info("Unathenticated User attempted to access protected URL: " + httpServletRequest.getRequestURI());
		
		httpServletResponse.sendRedirect("/home");
		
	}
	
}

