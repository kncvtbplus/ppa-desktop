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
@Table(name = "ppa_sector", uniqueConstraints = @UniqueConstraint(columnNames = {"ppa_id", "name"}))
public class PpaSector
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "ppa_id")
	private Ppa ppa;
	
	@Column(name = "position")
	private Long position;
	
	@Column(name = "name", nullable = false)
	private String name = "";

	@Column(name = "editable", nullable = false)
	private boolean editable = false;

	@Column(name = "selected", nullable = false)
	private boolean selected = false;

	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "ppaSector")
	@OrderBy("level DESC")
	private Set<PpaSectorLevel> ppaSectorLevels = new HashSet<>();
	
	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public Long getPosition()
	{
		return position;
	}

	public void setPosition(Long position)
	{
		this.position = position;
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

	public boolean getEditable()
	{
		return editable;
	}

	public void setEditable(boolean editable)
	{
		this.editable = editable;
	}

	public boolean getSelected()
	{
		return selected;
	}

	public void setSelected(boolean selected)
	{
		this.selected = selected;
	}

	public Set<PpaSectorLevel> getPpaSectorLevels()
	{
		return ppaSectorLevels;
	}

	public void setPpaSectorLevels(Set<PpaSectorLevel> ppaSectorLevels)
	{
		this.ppaSectorLevels = ppaSectorLevels;
	}

	public void addPpaSectorLevel(PpaSectorLevel ppaSectorLevel)
	{
		ppaSectorLevels.add(ppaSectorLevel);
		ppaSectorLevel.setPpaSector(this);
		
	}

	public void removePpaSectorLevel(PpaSectorLevel ppaSectorLevel)
	{
		ppaSectorLevels.remove(ppaSectorLevel);
		ppaSectorLevel.setPpaSector(null);
		
	}

}

