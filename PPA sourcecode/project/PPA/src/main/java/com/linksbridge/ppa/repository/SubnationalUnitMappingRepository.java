package com.linksbridge.ppa.repository;

import java.util.List;
import java.util.Optional;

import com.linksbridge.ppa.model.SubnationalUnit;
import com.linksbridge.ppa.model.SubnationalUnitMapping;

public interface SubnationalUnitMappingRepository extends CustomJpaRepository<SubnationalUnitMapping, Long>
{
	List<SubnationalUnit> findByIdIn(List<Long> subnationalUnitIds);

	Optional<SubnationalUnitMapping> findByDataSourceIdAndRegionColumnValue(Long dataSourceId, String value);

}

