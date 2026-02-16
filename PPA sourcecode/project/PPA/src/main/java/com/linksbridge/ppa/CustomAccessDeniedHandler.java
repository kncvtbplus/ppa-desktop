package com.linksbridge.ppa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Access denied handler. Replaces 403 page.
 * 
 * @author Tim
 *
 */
@Component
public class CustomAccessDeniedHandler implements AccessDeniedHandler
{
	private static final Logger LOGGER = LoggerFactory.getLogger(CustomAccessDeniedHandler.class);

	@Override
	public void handle
	(
			HttpServletRequest servletRequest,
			HttpServletResponse servletResponse,
			AccessDeniedException accessDeniedException
	) throws IOException, ServletException
	{
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

		if (authentication != null)
		{
			LOGGER.info("User '" + authentication.getName() + "' attempted to access protected URL: " + servletRequest.getRequestURI());
			
			servletResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);

		}
		
	}
	
}

