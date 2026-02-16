package com.linksbridge.ppa.model;

import java.util.Map;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

import com.linksbridge.ppa.util.Common;

@Entity
@Table(name = "metric", uniqueConstraints = @UniqueConstraint(columnNames = {"ppa_id", "metric_type_id"}))
public class Metric
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "ppa_id", nullable = false)
	private Ppa ppa;
	
	@ManyToOne
	@JoinColumn(name = "data_source_id")
	private DataSource dataSource;
	
	@ManyToOne
	@JoinColumn(name = "metric_type_id", nullable = false)
	private MetricType metricType;
	
	@Column(name = "selected", nullable = false)
	private boolean selected = false;

	@Column(name = "data_point_name", nullable = false)
	private String dataPointName = "";

	@Column(name = "data_source_column_name", nullable = false)
	private String dataSourceColumnName = "";

	@Column(name = "column_value_frequencies", nullable = false)
	private String ColumnValueFrequencies = "";

	@Column(name = "selected_column_values", nullable = false)
	private String selectedColumnValues = "";

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

	public DataSource getDataSource()
	{
		return dataSource;
	}

	public void setDataSource(DataSource dataSource)
	{
		this.dataSource = dataSource;
	}

	public MetricType getMetricType()
	{
		return metricType;
	}

	public void setMetricType(MetricType metric)
	{
		this.metricType = metric;
	}

	public boolean getSelected()
	{
		return selected;
	}

	public void setSelected(boolean selected)
	{
		this.selected = selected;
	}

	public String getDataPointName()
	{
		return dataPointName;
	}

	public void setDataPointName(String dataPointName)
	{
		this.dataPointName = dataPointName;
	}

	public String getDataSourceColumnName()
	{
		return dataSourceColumnName;
	}

	public void setDataSourceColumnName(String dataSourceColumnName)
	{
		this.dataSourceColumnName = dataSourceColumnName;
	}

	public Map<String, Long> getColumnValueFrequencies()
	{
		return Common.unpackFrequencyMap(ColumnValueFrequencies);
	}

	public void setColumnValueFrequencies(Map<String, Long> ColumnValueFrequencies)
	{
		this.ColumnValueFrequencies = Common.packFrequencyMap(ColumnValueFrequencies);
	}

	public String[] getSelectedColumnValues()
	{
		return Common.unpackStrings(selectedColumnValues);
	}

	public void setSelectedColumnValues(String[] selectedColumnValues)
	{
		this.selectedColumnValues = Common.packStrings(selectedColumnValues);
	}

}

