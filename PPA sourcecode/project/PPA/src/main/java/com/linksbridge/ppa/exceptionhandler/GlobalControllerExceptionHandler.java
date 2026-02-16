// NWL: enabled this one

package com.linksbridge.ppa.exceptionhandler;

import java.io.IOException;

import javax.servlet.http.HttpServletResponse;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;

import com.linksbridge.ppa.exceptionhandler.ApplicationException;

@ControllerAdvice
public class GlobalControllerExceptionHandler
{
    @ExceptionHandler(ApplicationException.class)
    @ResponseBody
	public String defaultErrorHandler(HttpServletResponse response, Exception e) throws IOException
	{
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        response.setContentType("text/plain");
        
        return e.getMessage();
        
	}

}
