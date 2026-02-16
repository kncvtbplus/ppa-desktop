package com.linksbridge.ppa.repository;

import java.util.List;

import com.linksbridge.ppa.model.PpaSector;

public interface PpaSectorRepository extends CustomJpaRepository<PpaSector, Long>
{
	List<PpaSector> findByIdIn(List<Long> ppaSectorIds);
	
}

