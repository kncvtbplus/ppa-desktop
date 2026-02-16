package com.linksbridge.ppa.model;

import java.util.Date;
import java.util.Map;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;

import com.linksbridge.ppa.util.Common;

@Entity
@Table(name = "output"/*, uniqueConstraints = @UniqueConstraint(columnNames = {"file_name"})*/)
public class Output
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "ppa_id")
	private Ppa ppa;
	
	@Column(name = "created")
	@Temporal(TemporalType.TIMESTAMP)
	private Date created;

	@Column(name = "file_name", nullable = false)
	private String fileName = "";

	@Column(name = "chart_file_names", nullable = false)
	private String chartFileNames = "";

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

	public Date getCreated()
	{
		return created;
	}

	public void setCreated(Date created)
	{
		this.created = created;
	}

	public String getFileName()
	{
		return fileName;
	}

	public void setFileName(String fileName)
	{
		this.fileName = fileName;
	}

	public Map<String, String> getChartFileNames()
	{
		return Common.unpackKeyValueMap(chartFileNames);
	}

	public void setChartFileNames(Map<String, String> chartFileNames)
	{
		this.chartFileNames = Common.packKeyValueMap(chartFileNames);
	}

}

