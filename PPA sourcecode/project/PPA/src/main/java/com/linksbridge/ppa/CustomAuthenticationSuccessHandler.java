package com.linksbridge.ppa;

import java.io.IOException;
import java.net.URL;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

@Component
public class CustomAuthenticationSuccessHandler implements AuthenticationSuccessHandler
{
	private static final Logger LOGGER = LoggerFactory.getLogger(CustomAuthenticationSuccessHandler.class);

	@Override
	public void onAuthenticationSuccess
	(
			HttpServletRequest httpServletRequest,
			HttpServletResponse httpServletResponse,
			Authentication authentication
	) throws IOException, ServletException
	{
		String scheme = httpServletRequest.getScheme();
		
		LOGGER.info("Request scheme: '" + scheme);
		
		URL url = new URL(httpServletRequest.getScheme(), httpServletRequest.getServerName(), "/");
		
		LOGGER.info("Redirect URL: '" + url);
		
//		httpServletResponse.sendRedirect(url.toString());
		httpServletResponse.sendRedirect("/");
		
	}
	
}

