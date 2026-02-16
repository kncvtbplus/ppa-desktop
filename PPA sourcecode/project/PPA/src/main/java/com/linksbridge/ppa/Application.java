package com.linksbridge.ppa;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.thymeleaf.spring5.SpringTemplateEngine;

import com.linksbridge.ppa.repository.CustomRepositoryImpl;
import com.linksbridge.thymeleaf.extras.dialect.UnescapedDataAttributeDialect;

@SpringBootApplication
@EnableJpaRepositories(repositoryBaseClass = CustomRepositoryImpl.class)
public class Application
{
	public static void main(String[] args)
	{
		ConfigurableApplicationContext applicationContext = SpringApplication.run(Application.class, args);
		
		// Thymeleaf unescaped data dialect
		
		applicationContext.getBean(SpringTemplateEngine.class)
		.addDialect
		(
				applicationContext.getBean(UnescapedDataAttributeDialect.class)
		)
		;
		
		// register session destroyed listener
		
		SpringApplication springApplication = new SpringApplication();
		springApplication.addListeners(new SessionDestroyedListener());
		
		// check system properties
		
		System.out.println("user.home=" + System.getProperty("user.home"));
		System.out.println("user.dir=" + System.getProperty("user.dir"));
		
	}
	
}

