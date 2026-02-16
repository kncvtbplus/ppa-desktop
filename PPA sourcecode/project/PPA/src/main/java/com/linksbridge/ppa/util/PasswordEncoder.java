package com.linksbridge.ppa.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class PasswordEncoder
{
	public static void main(String[] args)
	{
		if (args.length < 1)
		{
			System.out.println("Usage:\nPasswordEncoder <password>");
			System.exit(1);
		}
		
		System.out.println(new BCryptPasswordEncoder().encode(args[0]));
		
	}
}
