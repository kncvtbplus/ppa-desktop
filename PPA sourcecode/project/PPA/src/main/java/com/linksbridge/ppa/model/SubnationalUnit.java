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
import javax.persistence.UniqueConstraint;

@Entity
@Table(name = "subnational_unit", uniqueConstraints = @UniqueConstraint(columnNames = {"ppa_id", "name"}))
public class SubnationalUnit
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "ppa_id")
	private Ppa ppa;
	
	@Column(name = "name", nullable = false)
	private String name = "";

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "subnationalUnit")
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

	public String getName()
	{
		return name;
	}

	public void setName(String name)
	{
		this.name = name;
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
		subnationalUnitMapping.setSubnationalUnit(this);
		
	}

	public void removeSubnationalUnitMapping(SubnationalUnitMapping subnationalUnitMapping)
	{
		subnationalUnitMappings.remove(subnationalUnitMapping);
		subnationalUnitMapping.setSubnationalUnit(null);
		
	}

}

