package com.linksbridge.ppa.controller;

import java.util.LinkedHashMap;
import java.util.Map;

public class DataSourceInfo
{
	public String[] columnNames;
	public String[][] data;
	public final Map<String, Map<String, Long>> columnInfos = new LinkedHashMap<>();
	
}
