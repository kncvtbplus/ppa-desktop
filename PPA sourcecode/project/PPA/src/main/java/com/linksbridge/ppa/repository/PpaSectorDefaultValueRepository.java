package com.linksbridge.ppa.repository;

import java.util.List;

import com.linksbridge.ppa.model.PpaSectorDefaultValue;

public interface PpaSectorDefaultValueRepository extends CustomJpaRepository<PpaSectorDefaultValue, Long>
{
	List<PpaSectorDefaultValue> findAllByOrderByPosition();
	
}

