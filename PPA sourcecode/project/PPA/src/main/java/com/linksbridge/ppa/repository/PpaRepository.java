package com.linksbridge.ppa.repository;

import java.util.List;

import com.linksbridge.ppa.model.Ppa;

public interface PpaRepository extends CustomJpaRepository<Ppa, Long>
{
	List<Ppa> findByIdIn(List<Long> ppaIds);
	
}

