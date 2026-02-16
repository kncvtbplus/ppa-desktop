package com.linksbridge.ppa.model;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.OrderBy;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

import com.linksbridge.ppa.util.Common;

@Entity
@Table(name = "data_source", uniqueConstraints = @UniqueConstraint(columnNames = {"ppa_id", "user_file_id"}))
public class DataSource
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "ppa_id")
	private Ppa ppa;
	
	@ManyToOne
	@JoinColumn(name = "user_file_id")
	private UserFile userFile;
	
	@Column(name = "subnational_unit_column_name", nullable = false)
	private String subnationalUnitColumnName = "";
	
	@Column(name = "subnational_unit_value_frequencies", nullable = false)
	private String subnationalUnitValueFrequencies = "";
	
	@Column(name = "subnational_unit_selected_values", nullable = false)
	private String subnationalUnitSelectedValues = "";
	
	@Column(name = "facility_type_column_name", nullable = false)
	private String facilityTypeColumnName = "";
	
	@Column(name = "facility_type_column_values", nullable = false)
	private String facilityTypeValues = "";
	
	@Column(name = "facility_type_value_frequencies", nullable = false)
	private String facilityTypeValueFrequencies = "";
	
	@Column(name = "health_sector_column_name", nullable = false)
	private String healthSectorColumnName = "";
	
	@Column(name = "health_sector_column_values", nullable = false)
	private String healthSectorValues = "";
	
	@Column(name = "health_sector_value_frequencies", nullable = false)
	private String healthSectorValueFrequencies = "";
	
	@Column(name = "available_ppa_sector_mapping_value_combination_frequencies", nullable = false)
	private String ppaSectorMappingValueCombinationFrequencies = "";
	
	@Column(name = "subset_column1_name", nullable = false)
	private String subsetColumn1Name = "";
	
	@Column(name = "subset_column1_values", nullable = false)
	private String subsetColumn1Values = "";
	
	@Column(name = "subset_column1_value_frequencies", nullable = false)
	private String subsetColumn1ValueFrequencies = "";
	
	@Column(name = "subset_column1_selected_values", nullable = false)
	private String subsetColumn1SelectedValues = "";
	
	@Column(name = "subset_column2_name", nullable = false)
	private String subsetColumn2Name = "";
	
	@Column(name = "subset_column2_values", nullable = false)
	private String subsetColumn2Values = "";
	
	@Column(name = "subset_column2_value_frequencies", nullable = false)
	private String subsetColumn2ValueFrequencies = "";
	
	@Column(name = "subset_column2_selected_values", nullable = false)
	private String subsetColumn2SelectedValues = "";
	
	@Column(name = "selected_row_count", nullable = false)
	private int selectedRowCount = 0;
	
	@Column(name = "weight_column_name", nullable = false)
	private String weightColumnName = "";
	
	@Column(name = "weight_multiplier", nullable = false)
	private BigDecimal weightMultiplier = new BigDecimal(1);
	
	@OneToMany(mappedBy = "dataSource"/*, cascade = CascadeType.ALL, orphanRemoval = true*/)
	@OrderBy("id ASC")
	private Set<Metric> metrics = new HashSet<>();
	
	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "dataSource")
	@OrderBy("id ASC")
	private Set<PpaSectorMapping> ppaSectorMappings = new HashSet<>();
	
	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "dataSource")
	@OrderBy("id ASC")
	private Set<SubnationalUnitMapping> subnationalUnitMappings = new HashSet<>();
	
	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public Ppa getPpa()
	{
		return ppa;
	}

	public void setPpa(Ppa ppa)
	{
		this.ppa = ppa;
	}

	public UserFile getUserFile()
	{
		return userFile;
	}

	public void setUserFile(UserFile userFile)
	{
		this.userFile = userFile;
	}

	public String getSubnationalUnitColumnName()
	{
		return subnationalUnitColumnName;
	}

	public void setSubnationalUnitColumnName(String subnationalUnitColumnName)
	{
		this.subnationalUnitColumnName = subnationalUnitColumnName;
	}

	public Map<String, Long> getSubnationalUnitValueFrequencies()
	{
		return Common.unpackFrequencyMap(subnationalUnitValueFrequencies);
	}

	public void setSubnationalUnitValueFrequencies(Map<String, Long> subnationalUnitValueFrequencies)
	{
		this.subnationalUnitValueFrequencies = Common.packFrequencyMap(subnationalUnitValueFrequencies);
	}

	public String[] getSubnationalUnitSelectedValues()
	{
		return Common.unpackStrings(subnationalUnitSelectedValues);
	}

	public void setSubnationalUnitSelectedValues(String[] subnationalUnitSelectedValues)
	{
		this.subnationalUnitSelectedValues = Common.packStrings(subnationalUnitSelectedValues);
	}

	public String getFacilityTypeColumnName()
	{
		return facilityTypeColumnName;
	}

	public void setFacilityTypeColumnName(String facilityTypeColumnName)
	{
		this.facilityTypeColumnName = facilityTypeColumnName;
	}

	public String[] getFacilityTypeValues()
	{
		return Common.unpackStrings(facilityTypeValues);
	}

	public void setFacilityTypeValues(String[] facilityTypeValues)
	{
		this.facilityTypeValues = Common.packStrings(facilityTypeValues);
	}

	public Map<String, Long> getFacilityTypeValueFrequencies()
	{
		return Common.unpackFrequencyMap(facilityTypeValueFrequencies);
	}

	public void setFacilityTypeValueFrequencies(Map<String, Long> facilityTypeValueFrequencies)
	{
		this.facilityTypeValueFrequencies = Common.packFrequencyMap(facilityTypeValueFrequencies);
	}

	public String getHealthSectorColumnName()
	{
		return healthSectorColumnName;
	}

	public void setHealthSectorColumnName(String healthSectorColumnName)
	{
		this.healthSectorColumnName = healthSectorColumnName;
	}

	public String[] getHealthSectorValues()
	{
		return Common.unpackStrings(healthSectorValues);
	}

	public void setHealthSectorValues(String[] healthSectorValues)
	{
		this.healthSectorValues = Common.packStrings(healthSectorValues);
	}

	public Map<String, Long> getHealthSectorValueFrequencies()
	{
		return Common.unpackFrequencyMap(healthSectorValueFrequencies);
	}

	public void setHealthSectorValueFrequencies(Map<String, Long> healthSectorValueFrequencies)
	{
		this.healthSectorValueFrequencies = Common.packFrequencyMap(healthSectorValueFrequencies);
	}

	public Map<String, Long> getPpaSectorMappingValueCombinationFrequencies()
	{
		return Common.unpackFrequencyMap(ppaSectorMappingValueCombinationFrequencies);
	}

	public void setPpaSectorMappingValueCombinationFrequencies(Map<String, Long> ppaSectorMappingValueCombinationFrequencies)
	{
		this.ppaSectorMappingValueCombinationFrequencies = Common.packFrequencyMap(ppaSectorMappingValueCombinationFrequencies);
	}

	public String getSubsetColumn1Name()
	{
		return subsetColumn1Name;
	}

	public void setSubsetColumn1Name(String subsetColumn1Name)
	{
		this.subsetColumn1Name = subsetColumn1Name;
	}

	public String[] getSubsetColumn1Values()
	{
		return Common.unpackStrings(subsetColumn1Values);
	}

	public void setSubsetColumn1Values(String[] subsetColumn1Values)
	{
		this.subsetColumn1Values = Common.packStrings(subsetColumn1Values);
	}

	public Map<String, Long> getSubsetColumn1ValueFrequencies()
	{
		return Common.unpackFrequencyMap(subsetColumn1ValueFrequencies);
	}

	public void setSubsetColumn1ValueFrequencies(Map<String, Long> subsetColumn1ValueFrequencies)
	{
		this.subsetColumn1ValueFrequencies = Common.packFrequencyMap(subsetColumn1ValueFrequencies);
	}

	public String[] getSubsetColumn1SelectedValues()
	{
		return Common.unpackStrings(subsetColumn1SelectedValues);
	}

	public void setSubsetColumn1SelectedValues(String[] subsetColumn1SelectedValues)
	{
		this.subsetColumn1SelectedValues = Common.packStrings(subsetColumn1SelectedValues);
	}

	public String getSubsetColumn2Name()
	{
		return subsetColumn2Name;
	}

	public void setSubsetColumn2Name(String subsetColumn2Name)
	{
		this.subsetColumn2Name = subsetColumn2Name;
	}

	public String[] getSubsetColumn2Values()
	{
		return Common.unpackStrings(subsetColumn2Values);
	}

	public void setSubsetColumn2Values(String[] subsetColumn2Values)
	{
		this.subsetColumn2Values = Common.packStrings(subsetColumn2Values);
	}

	public Map<String, Long> getSubsetColumn2ValueFrequencies()
	{
		return Common.unpackFrequencyMap(subsetColumn2ValueFrequencies);
	}

	public void setSubsetColumn2ValueFrequencies(Map<String, Long> subsetColumn2ValueFrequencies)
	{
		this.subsetColumn2ValueFrequencies = Common.packFrequencyMap(subsetColumn2ValueFrequencies);
	}

	public String[] getSubsetColumn2SelectedValues()
	{
		return Common.unpackStrings(subsetColumn2SelectedValues);
	}

	public void setSubsetColumn2SelectedValues(String[] subsetColumn2SelectedValues)
	{
		this.subsetColumn2SelectedValues = Common.packStrings(subsetColumn2SelectedValues);
	}

	public int getSelectedRowCount()
	{
		return selectedRowCount;
	}

	public void setSelectedRowCount(int selectedRowCount)
	{
		this.selectedRowCount = selectedRowCount;
	}

	public String getWeightColumnName()
	{
		return weightColumnName;
	}

	public void setWeightColumnName(String weightColumnName)
	{
		this.weightColumnName = weightColumnName;
	}

	public BigDecimal getWeightMultiplier()
	{
		return weightMultiplier;
	}

	public void setWeightMultiplier(BigDecimal weightMultiplier)
	{
		this.weightMultiplier = weightMultiplier;
	}

	public Set<Metric> getMetrics()
	{
		return metrics;
	}

	public void setMetrics(Set<Metric> metric)
	{
		this.metrics = metric;
	}

	public void addMetric(Metric metric)
	{
		metrics.add(metric);
		metric.setDataSource(this);
		
	}

	public void removeMetric(Metric metric)
	{
		metrics.remove(metric);
		metric.setDataSource(null);
		
	}

	public Set<PpaSectorMapping> getPpaSectorMappings()
	{
		return ppaSectorMappings;
	}

	public void setPpaSectorMappings(Set<PpaSectorMapping> ppaSectorMappings)
	{
		this.ppaSectorMappings = ppaSectorMappings;
	}

	public void addPpaSectorMapping(PpaSectorMapping ppaSectorMapping)
	{
		ppaSectorMappings.add(ppaSectorMapping);
		ppaSectorMapping.setDataSource(this);
		
	}

	public void removePpaSectorMapping(PpaSectorMapping ppaSectorMapping)
	{
		ppaSectorMappings.remove(ppaSectorMapping);
		ppaSectorMapping.setDataSource(null);
		
	}

	public Set<SubnationalUnitMapping> getSubnationalUnitMappings()
	{
		return subnationalUnitMappings;
	}

	public void setSubnationalUnitMappings(Set<SubnationalUnitMapping> subnationalUnitMappings)
	{
		this.subnationalUnitMappings = subnationalUnitMappings;
	}

	public void addSubnationalUnitMapping(SubnationalUnitMapping subnationalUnitMapping)
	{
		subnationalUnitMappings.add(subnationalUnitMapping);
		subnationalUnitMapping.setDataSource(this);
		
	}

	public void removeSubnationalUnitMapping(SubnationalUnitMapping subnationalUnitMapping)
	{
		subnationalUnitMappings.remove(subnationalUnitMapping);
		subnationalUnitMapping.setDataSource(null);
		
	}

}

