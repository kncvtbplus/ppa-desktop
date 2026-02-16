package com.linksbridge.ppa.repository;

import java.util.List;

import com.linksbridge.ppa.model.MetricType;

public interface MetricTypeRepository extends CustomJpaRepository<MetricType, Long>
{
	List<MetricType> findAllByOrderByIdAsc();

}

