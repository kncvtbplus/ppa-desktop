package com.linksbridge.ppa.model;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

@Entity
@Table(name = "ppa_sector_default_value", uniqueConstraints = @UniqueConstraint(columnNames = {"position"}))
public class PpaSectorDefaultValue
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@Column(name = "position", nullable = false)
	private long position = 0L;
	
	@Column(name = "name", nullable = false)
	private String name = "";

	@Column(name = "editable", nullable = false)
	private boolean editable = false;

	public Long getId()
	{
		return id;
	}

	public void setId(Long id)
	{
		this.id = id;
	}

	public long getPosition()
	{
		return position;
	}

	public void setPosition(long position)
	{
		this.position = position;
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

}

