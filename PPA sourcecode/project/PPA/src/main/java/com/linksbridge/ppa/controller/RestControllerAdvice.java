package com.linksbridge.ppa.controller;

import org.springframework.beans.propertyeditors.StringArrayPropertyEditor;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.InitBinder;

@ControllerAdvice
public class RestControllerAdvice
{
	@InitBinder
	public void init(WebDataBinder dataBinder)
	{
		dataBinder.registerCustomEditor(String[].class, new StringArrayPropertyEditor(",", false, false));
		
	}
	
	// NWL
	// @ExceptionHandler(Exception.class)
 //   public ResponseEntity<Object> handleException(Exception ex) {
 //       Map<String, Object> body = new HashMap<>();
 //       body.put("message", "An error occurred");

 //       return new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR);
 //   }
    
	
}

