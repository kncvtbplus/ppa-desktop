package com.linksbridge.ppa.repository;

import java.util.List;

import com.linksbridge.ppa.model.Output;

public interface OutputRepository extends CustomJpaRepository<Output, Long>
{
	List<Output> findByIdIn(List<Long> outputIds);

}

