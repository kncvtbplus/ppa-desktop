package com.linksbridge.ppa.repository;

import java.util.List;
import java.util.Optional;

import com.linksbridge.ppa.model.DataSource;

public interface DataSourceRepository extends CustomJpaRepository<DataSource, Long>
{
	List<DataSource> findByIdIn(List<Long> dataSourceIds);

	Optional<DataSource> findByPpaIdAndUserFileId(Long ppaId, Long userFileId);

}

