package com.linksbridge.ppa.repository;

import java.util.Set;

import com.linksbridge.ppa.model.Metric;

public interface MetricRepository extends CustomJpaRepository<Metric, Long>
{

	Set<Metric> findByPpaIdAndSelectedOrderById(Long id, Boolean selected);

}

