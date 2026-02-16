package com.linksbridge.ppa.repository;

import java.util.Optional;

import com.linksbridge.ppa.model.PpaSectorMapping;

public interface PpaSectorMappingRepository extends CustomJpaRepository<PpaSectorMapping, Long>
{
	Optional<PpaSectorMapping> findByDataSourceIdAndValueCombination(Long dataSourceId, String valueCombination);
	
}

