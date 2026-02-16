package com.linksbridge.ppa.model;

import java.util.HashSet;
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

@Entity
@Table(name = "ppa"/*, uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "name"})*/)
public class Ppa
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "account_id")
	private Account account;
	
	@Column(name = "name", nullable = false)
	private String name = "";

	@Column(name = "aggregation_level")
	private String aggregationLevel = "National";

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "ppa")
	@OrderBy("id ASC")
	private Set<DataSource> dataSources = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "ppa")
	@OrderBy("metric_type_id ASC")
	private Set<Metric> metrics = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "ppa")
	@OrderBy("position ASC")
	private Set<PpaSector> ppaSectors = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "ppa")
	@OrderBy("name ASC")
	private Set<SubnationalUnit> subnationalUnits = new HashSet<>();

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "ppa")
	@OrderBy("id ASC")
	private Set<Output> outputs = new HashSet<>();

	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public Account getAccount()
	{
		return account;
	}

	public void setAccount(Account account)
	{
		this.account = account;
	}

	public String getName()
	{
		return name;
	}

	public void setName(String name)
	{
		this.name = name;
	}

	public String getAggregationLevel()
	{
		return aggregationLevel;
	}

	public void setAggregationLevel(String aggregationLevel)
	{
		this.aggregationLevel = aggregationLevel;
	}

	public Set<DataSource> getDataSources()
	{
		return dataSources;
	}

	public void setDataSources(Set<DataSource> dataSources)
	{
		this.dataSources = dataSources;
	}

	public void addDataSource(DataSource dataSource)
	{
		dataSources.add(dataSource);
		dataSource.setPpa(this);
		
	}

	public void removeDataSource(DataSource dataSource)
	{
		dataSources.remove(dataSource);
		dataSource.setPpa(null);
		
	}

	public Set<Metric> getMetrics()
	{
		return metrics;
	}

	public void setMetrics(Set<Metric> metrics)
	{
		this.metrics = metrics;
	}

	public void addMetric(Metric ppaMetric)
	{
		metrics.add(ppaMetric);
		ppaMetric.setPpa(this);
		
	}

	public void removeMetric(Metric metric)
	{
		metrics.remove(metric);
		metric.setPpa(null);
		
	}

	public Set<PpaSector> getPpaSectors()
	{
		return ppaSectors;
	}

	public void setPpaSectors(Set<PpaSector> healthSectors)
	{
		this.ppaSectors = healthSectors;
	}

	public void addPpaSector(PpaSector ppaSector)
	{
		ppaSectors.add(ppaSector);
		ppaSector.setPpa(this);
		
	}

	public void removePpaSector(PpaSector ppaSector)
	{
		ppaSectors.remove(ppaSector);
		ppaSector.setPpa(null);
		
	}

	public Set<SubnationalUnit> getSubnationalUnits()
	{
		return subnationalUnits;
	}

	public void setSubnationalUnits(Set<SubnationalUnit> healthSectors)
	{
		this.subnationalUnits = healthSectors;
	}

	public void addSubnationalUnit(SubnationalUnit subnationalUnit)
	{
		subnationalUnits.add(subnationalUnit);
		subnationalUnit.setPpa(this);
		
	}

	public void removeSubnationalUnit(SubnationalUnit subnationalUnit)
	{
		subnationalUnits.remove(subnationalUnit);
		subnationalUnit.setPpa(null);
		
	}

	public Set<Output> getOutputs()
	{
		return outputs;
	}

	public void setOutputs(Set<Output> healthSectors)
	{
		this.outputs = healthSectors;
	}

	public void addOutput(Output output)
	{
		outputs.add(output);
		output.setPpa(this);
		
	}

	public void removeOutput(Output output)
	{
		outputs.remove(output);
		output.setPpa(null);
		
	}

}

