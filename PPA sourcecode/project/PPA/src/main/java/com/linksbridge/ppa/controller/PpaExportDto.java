package com.linksbridge.ppa.controller;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * DTO graph used for exporting and importing a single PPA configuration
 * (without users/accounts or generated outputs).
 *
 * The JSON representation of this class is stored as ppa.json inside the
 * .ppa ZIP archive.
 */
public class PpaExportDto
{
	public Long originalId;
	public String name;
	public String aggregationLevel;

	public List<DataSourceDto> dataSources;
	public List<MetricDto> metrics;
	public List<PpaSectorDto> ppaSectors;
	public List<PpaSectorLevelDto> ppaSectorLevels;
	public List<PpaSectorMappingDto> ppaSectorMappings;
	public List<SubnationalUnitDto> subnationalUnits;
	public List<SubnationalUnitMappingDto> subnationalUnitMappings;
	public List<UserFileDto> userFiles;

	public static class DataSourceDto
	{
		public Long originalId;
		public Long userFileOriginalId;

		public String subnationalUnitColumnName;
		public Map<String, Long> subnationalUnitValueFrequencies;
		public String[] subnationalUnitSelectedValues;

		public String facilityTypeColumnName;
		public String[] facilityTypeValues;
		public Map<String, Long> facilityTypeValueFrequencies;

		public String healthSectorColumnName;
		public String[] healthSectorValues;
		public Map<String, Long> healthSectorValueFrequencies;

		public Map<String, Long> ppaSectorMappingValueCombinationFrequencies;

		public String subsetColumn1Name;
		public String[] subsetColumn1Values;
		public Map<String, Long> subsetColumn1ValueFrequencies;
		public String[] subsetColumn1SelectedValues;

		public String subsetColumn2Name;
		public String[] subsetColumn2Values;
		public Map<String, Long> subsetColumn2ValueFrequencies;
		public String[] subsetColumn2SelectedValues;

		public int selectedRowCount;

		public String weightColumnName;
		public BigDecimal weightMultiplier;
	}

	public static class MetricDto
	{
		public Long originalId;
		public Long dataSourceOriginalId;
		public Long metricTypeId;
		public boolean selected;
		public String dataPointName;
		public String dataSourceColumnName;
		public Map<String, Long> columnValueFrequencies;
		public String[] selectedColumnValues;
	}

	public static class PpaSectorDto
	{
		public Long originalId;
		public Long position;
		public String name;
		public boolean editable;
		public boolean selected;
	}

	public static class PpaSectorLevelDto
	{
		public Long originalId;
		public Long ppaSectorOriginalId;
		public String level;
	}

	public static class PpaSectorMappingDto
	{
		public Long originalId;
		public Long dataSourceOriginalId;
		public Long ppaSectorLevelOriginalId;
		public String valueCombination;
	}

	public static class SubnationalUnitDto
	{
		public Long originalId;
		public String name;
	}

	public static class SubnationalUnitMappingDto
	{
		public Long originalId;
		public Long dataSourceOriginalId;
		public Long subnationalUnitOriginalId;
		public String regionColumnValue;
	}

	public static class UserFileDto
	{
		public Long originalId;
		public String fileName;
		/**
		 * Path of the binary entry inside the .ppa ZIP,
		 * e.g. "data/1-population.csv".
		 */
		public String fileRef;
	}
}

