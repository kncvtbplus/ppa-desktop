package com.linksbridge.ppa.model;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

@Entity
@Table(name = "subnational_unit_mapping", uniqueConstraints = @UniqueConstraint(columnNames = {"data_source_id", "region_column_value"}))
public class SubnationalUnitMapping
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "data_source_id", nullable = false)
	private DataSource dataSource;
	
	@ManyToOne
	@JoinColumn(name = "subnational_unit_id", nullable = false)
	private SubnationalUnit subnationalUnit;
	
	@Column(name = "region_column_value", nullable = false)
	private String regionColumnValue = "";

	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public DataSource getDataSource()
	{
		return dataSource;
	}

	public void setDataSource(DataSource dataSource)
	{
		this.dataSource = dataSource;
	}

	public SubnationalUnit getSubnationalUnit()
	{
		return subnationalUnit;
	}

	public void setSubnationalUnit(SubnationalUnit subnationalUnit)
	{
		this.subnationalUnit = subnationalUnit;
	}

	public String getRegionColumnValue()
	{
		return regionColumnValue;
	}

	public void setRegionColumnValue(String regionColumnValue)
	{
		this.regionColumnValue = regionColumnValue;
	}

}

