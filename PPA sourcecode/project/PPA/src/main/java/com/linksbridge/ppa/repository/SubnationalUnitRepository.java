package com.linksbridge.ppa.repository;

import java.util.List;

import com.linksbridge.ppa.model.SubnationalUnit;

public interface SubnationalUnitRepository extends CustomJpaRepository<SubnationalUnit, Long>
{
	List<SubnationalUnit> findByIdIn(List<Long> subnationalUnitIds);

}

