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
@Table(name = "ppa_sector_mapping", uniqueConstraints = @UniqueConstraint(columnNames = {"data_source_id", "ppa_sector_level_id", "value_combination"}))
public class PpaSectorMapping
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "data_source_id", nullable = false)
	private DataSource dataSource;
	
	@ManyToOne
	@JoinColumn(name = "ppa_sector_level_id", nullable = false)
	private PpaSectorLevel ppaSectorLevel;
	
	@Column(name = "value_combination", nullable = false)
	private String valueCombination = "";

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

	public PpaSectorLevel getPpaSectorLevel()
	{
		return ppaSectorLevel;
	}

	public void setPpaSectorLevel(PpaSectorLevel ppaSector)
	{
		this.ppaSectorLevel = ppaSector;
	}

	public String getValueCombination()
	{
		return valueCombination;
	}

	public void setValueCombination(String valueCombination)
	{
		this.valueCombination = valueCombination;
	}

}

