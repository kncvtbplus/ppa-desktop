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

import com.linksbridge.ppa.util.Common;

@Entity
@Table(name = "user_file", uniqueConstraints = @UniqueConstraint(columnNames = {"account_id", "file_name"}))
public class UserFile
{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	
	@ManyToOne
	@JoinColumn(name = "account_id")
	private Account account;
	
	@Column(name = "s3_file_name", nullable = false)
	private String s3FileName;

	@Column(name = "file_name", nullable = false)
	private String fileName;

	@Column(name = "column_names", nullable = false)
	private String columnNames = "";
	
	@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "userFile")
	@OrderBy("id ASC")
	private Set<DataSource> dataSources = new HashSet<>();
	
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

	public String getS3FileName()
	{
		return s3FileName;
	}

	public void setS3FileName(String s3FileName)
	{
		this.s3FileName = s3FileName;
	}

	public String getFileName()
	{
		return fileName;
	}

	public void setFileName(String fileName)
	{
		this.fileName = fileName;
	}

	public String[] getColumnNames()
	{
		return Common.unpackStrings(columnNames);
	}

	public void setColumnNames(String[] columnNames)
	{
		this.columnNames = Common.packStrings(columnNames);
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
		dataSource.setUserFile(this);
		
	}

	public void removeDataSource(DataSource dataSource)
	{
		dataSources.remove(dataSource);
		dataSource.setUserFile(null);
		
	}

}

