package com.linksbridge.ppa.util;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.text.StringTokenizer;

import com.linksbridge.ppa.exceptionhandler.ApplicationException;

public class Common
{
	// string value separators
	
	private static final char RECORD_SEPARATOR = '\n';
	private static final char FIELD_SEPARATOR = '\t';
	public static final char TOKEN_SEPARATOR = '\1';
	
	private static final StringTokenizer recordStringTokenizer = new StringTokenizer();
	static
	{
		recordStringTokenizer.setDelimiterChar(RECORD_SEPARATOR);
		recordStringTokenizer.setIgnoreEmptyTokens(false);
	}
	
	private static final StringTokenizer fieldStringTokenizer = new StringTokenizer();
	static
	{
		fieldStringTokenizer.setDelimiterChar(FIELD_SEPARATOR);
		fieldStringTokenizer.setIgnoreEmptyTokens(false);
	}
	
	private static final StringTokenizer tokenStringTokenizer = new StringTokenizer();
	static
	{
		tokenStringTokenizer.setDelimiterChar(TOKEN_SEPARATOR);
		tokenStringTokenizer.setIgnoreEmptyTokens(false);
	}
	
	/**
	 * Packs string values into separated list
	 * 
	 * @param strings
	 * @return
	 */
	public static String packStrings(String[] strings)
	{
		return StringUtils.join(strings, RECORD_SEPARATOR);

	}
	public static String packStrings(List<String> strings)
	{
		return StringUtils.join(strings, RECORD_SEPARATOR);

	}
	
	/**
	 * Unpacks string values from separated list
	 * 
	 * @param code
	 * @return
	 */
	public static String[] unpackStrings(String string)
	{
		return recordStringTokenizer.reset(string).getTokenArray();

	}
	
	/**
	 * Packs string:integer values into separated list
	 * 
	 * @param strings
	 * @return
	 */
	public static String packFrequencyMap(Map<String, Long> frequencies)
	{
		List<String> rows = new ArrayList<>();
		
		for (Map.Entry<String, Long> frequencyEntry : frequencies.entrySet())
		{
			String value = frequencyEntry.getKey();
			Long frequency = frequencyEntry.getValue();
			
			String row = value + FIELD_SEPARATOR + frequency.toString();
			rows.add(row);
			
		}
		
		return StringUtils.join(rows, RECORD_SEPARATOR);

	}
	
	/**
	 * Unpacks string:integer values from separated list
	 * 
	 * @param code
	 * @return
	 */
	public static Map<String, Long> unpackFrequencyMap(String string)
	{
		String[] rows = recordStringTokenizer.reset(string).getTokenArray();
		
		Map<String, Long> frequencies = new LinkedHashMap<>();
		
		for (String row : rows)
		{
			String[] tokens = fieldStringTokenizer.reset(row).getTokenArray();
			
			if (tokens.length != 2)
			{
				throw new ApplicationException("Wrong frequency map packed format. Record does not contain exactly two fields: " + row + ".");
				
			}
			
			try
			{
				frequencies.put(tokens[0], Long.valueOf(tokens[1]));
			}
			catch (NumberFormatException e)
			{
				throw new ApplicationException("Wrong frequency map packed format. Second field is not an integer: " + row + ".", e);
				
			}
			
		}
		
		return frequencies;

	}
	
	/**
	 * Packs string:string values into separated list
	 * 
	 * @param strings
	 * @return
	 */
	public static String packKeyValueMap(Map<String, String> map)
	{
		List<String> rows = new ArrayList<>();
		
		for (Map.Entry<String, String> mapEntry : map.entrySet())
		{
			String key = mapEntry.getKey();
			String value = mapEntry.getValue();
			
			String row = key + FIELD_SEPARATOR + value;
			rows.add(row);
			
		}
		
		return StringUtils.join(rows, RECORD_SEPARATOR);

	}
	
	/**
	 * Unpacks string:string values from separated list
	 * 
	 * @param code
	 * @return
	 */
	public static Map<String, String> unpackKeyValueMap(String string)
	{
		String[] rows = recordStringTokenizer.reset(string).getTokenArray();
		
		Map<String, String> map = new LinkedHashMap<>();
		
		for (String row : rows)
		{
			String[] tokens = fieldStringTokenizer.reset(row).getTokenArray();
			
			if (tokens.length != 2)
			{
				throw new ApplicationException("Wrong map packed format. Record does not contain exactly two fields: " + row + ".");
				
			}
			
			map.put(tokens[0], tokens[1]);
			
		}
		
		return map;

	}
	
	/**
	 * Packs string,string value pairs into separated list
	 * 
	 * @param strings
	 * @return
	 */
	public static String packTokens(String[] tokens)
	{
		return StringUtils.join(tokens, TOKEN_SEPARATOR);

	}
	
	/**
	 * Unpacks string,string value pairs from separated list
	 * 
	 * @param code
	 * @return
	 */
	public static String[] unpackTokens(String string)
	{
		return tokenStringTokenizer.reset(string).getTokenArray();

	}
	
}
