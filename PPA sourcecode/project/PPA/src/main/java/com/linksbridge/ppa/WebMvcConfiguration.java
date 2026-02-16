package com.linksbridge.ppa;

import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.web.session.HttpSessionEventPublisher;
import org.springframework.web.servlet.LocaleResolver;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver;
import org.springframework.web.servlet.i18n.LocaleChangeInterceptor;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.transfer.TransferManager;
import com.amazonaws.services.s3.transfer.TransferManagerBuilder;
import com.amazonaws.services.simpleemail.AmazonSimpleEmailService;
import com.amazonaws.services.simpleemail.AmazonSimpleEmailServiceClientBuilder;
import com.linksbridge.thymeleaf.extras.dialect.UnescapedDataAttributeDialect;

@Configuration
public class WebMvcConfiguration implements WebMvcConfigurer
{
	@Override
	public void addViewControllers(ViewControllerRegistry registry)
	{
		registry.addViewController("/").setViewName("index");
		registry.addViewController("/home").setViewName("home");
registry.addViewController("/test").setViewName("test");
		registry.addViewController("/registerUser").setViewName("registerUser");
		registry.addViewController("/loginUser").setViewName("loginUser");
		registry.addViewController("/resetPassword").setViewName("resetPassword");
//		registry.addViewController("/login").setViewName("login");
		registry.addViewController("/403").setViewName("403");
		registry.addViewController("/administration").setViewName("administration");
	}

	@Override
	public void addInterceptors(InterceptorRegistry interceptorRegistry)
	{
		interceptorRegistry.addInterceptor(localeChangeInterceptor());
		interceptorRegistry.addInterceptor(refreshSessionInterceptor());
		
	}
	
	/**
	 * Register HttpSessionEventPublisher to listen to SessionDestroyedEvent.
	 * 
	 * @return
	 */
	@Bean
	public ServletListenerRegistrationBean<HttpSessionEventPublisher> httpSessionEventPublisher()
	{
	    return new ServletListenerRegistrationBean<HttpSessionEventPublisher>(new HttpSessionEventPublisher());
	    
	}
	
	@Bean
	public LocaleResolver localeResolver()
	{
		return new AcceptHeaderLocaleResolver();
	}

	@Bean
	public LocaleChangeInterceptor localeChangeInterceptor()
	{
		LocaleChangeInterceptor localeChangeInterceptor = new LocaleChangeInterceptor();
		localeChangeInterceptor.setParamName("language");
		
		return localeChangeInterceptor;
		
	}
	
	@Bean
	public RefreshSessionInterceptor refreshSessionInterceptor()
	{
		return new RefreshSessionInterceptor();
		
	}
	
	@Bean
	UnescapedDataAttributeDialect unescapedDataAttributeDialect()
	{
		return new UnescapedDataAttributeDialect();
	}
	
	@Bean
	AmazonS3 amazonS3Client()
	{
		return AmazonS3ClientBuilder.defaultClient();
		
	}
	
	@Bean
	TransferManager transferManager()
	{
		return TransferManagerBuilder.standard().withS3Client(amazonS3Client()).build();
		
	}
	
	@Bean
	AmazonSimpleEmailService amazonSimpleEmailService()
	{
		return AmazonSimpleEmailServiceClientBuilder.defaultClient();
		
	}
	
}

