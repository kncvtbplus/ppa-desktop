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
@Table(name = "ppa_sector_level", uniqueConstraints = @UniqueConstraint(columnNames = {"ppa_sector_id", "level"}))
public class PpaSectorLevel
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "ppa_sector_id", nullable = false)
	private PpaSector ppaSector;
	
	@Column(name = "level", nullable = false)
	private String level = "";

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "ppaSectorLevel")
	@OrderBy("id ASC")
	private Set<PpaSectorMapping> ppaSectorMappings = new HashSet<>();
	
	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public PpaSector getPpaSector()
	{
		return ppaSector;
	}

	public void setPpaSector(PpaSector ppaSector)
	{
		this.ppaSector = ppaSector;
	}

	public String getLevel()
	{
		return level;
	}

	public void setLevel(String level)
	{
		this.level = level;
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
		ppaSectorMapping.setPpaSectorLevel(this);
		
	}

	public void removePpaSectorMapping(PpaSectorMapping ppaSectorMapping)
	{
		ppaSectorMappings.remove(ppaSectorMapping);
		ppaSectorMapping.setPpaSectorLevel(null);
		
	}

}

