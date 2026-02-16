package com.linksbridge.ppa.model;

import java.util.HashSet;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.OneToMany;
import javax.persistence.OrderBy;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

@Entity
@Table(name = "metric_type", uniqueConstraints = @UniqueConstraint(columnNames = {"name"}))
public class MetricType
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@Column(name = "name", nullable = false)
	private String name;

	@Column(name = "type", nullable = false)
	private String type;

	@Column(name = "subtype")
	private String subtype;

	@Column(name = "r_name")
	private String rName;

	@Column(name = "required", nullable = false)
	private boolean required = false;

	@Column(name = "column_value_filter", nullable = false)
	private boolean columnValueFilter = true;

	@Column(name = "r_header", nullable = false)
	private String rHeader = "";

	@Column(name = "r_header_availability", nullable = false)
	private String rHeaderAvailability = "";

	@Column(name = "r_header_access", nullable = false)
	private String rHeaderAccess = "";

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "metricType")
	@OrderBy("id ASC")
	private Set<Metric> metrics = new HashSet<>();

	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public String getName()
	{
		return name;
	}

	public void setName(String name)
	{
		this.name = name;
	}

	public String getType()
	{
		return type;
	}

	public void setType(String type)
	{
		this.type = type;
	}

	public String getSubtype()
	{
		return subtype;
	}

	public void setSubtype(String subtype)
	{
		this.subtype = subtype;
	}

	public String getRName()
	{
		return rName;
	}

	public void setRName(String rName)
	{
		this.rName = rName;
	}

	public boolean getRequired()
	{
		return required;
	}

	public void setRequired(boolean required)
	{
		this.required = required;
	}

	public boolean getColumnValueFilter()
	{
		return columnValueFilter;
	}

	public void setColumnValueFilter(boolean columnValueFilter)
	{
		this.columnValueFilter = columnValueFilter;
	}

	public String getRHeader()
	{
		return rHeader;
	}

	public void setRHeader(String rHeader)
	{
		this.rHeader = rHeader;
	}

	public String getRHeaderAvailability()
	{
		return rHeaderAvailability;
	}

	public void setRHeaderAvailability(String rHeaderAvailability)
	{
		this.rHeaderAvailability = rHeaderAvailability;
	}

	public String getRHeaderAccess()
	{
		return rHeaderAccess;
	}

	public void setRHeaderAccess(String rHeaderAccess)
	{
		this.rHeaderAccess = rHeaderAccess;
	}

	public Set<Metric> getMetrics()
	{
		return metrics;
	}

	public void setMetrics(Set<Metric> metrics)
	{
		this.metrics = metrics;
	}

	public void addMetric(Metric metric)
	{
		metrics.add(metric);
		metric.setMetricType(this);
		
	}

	public void removeMetric(Metric metric)
	{
		metrics.remove(metric);
		metric.setMetricType(null);
		
	}

}

