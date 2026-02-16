package com.linksbridge.ppa.repository;

import java.util.Optional;

import com.linksbridge.ppa.model.PpaSectorLevel;

public interface PpaSectorLevelRepository extends CustomJpaRepository<PpaSectorLevel, Long>
{
	Optional<PpaSectorLevel> findByPpaSectorIdAndLevel(Long ppaSectorId, String level);
	
}

