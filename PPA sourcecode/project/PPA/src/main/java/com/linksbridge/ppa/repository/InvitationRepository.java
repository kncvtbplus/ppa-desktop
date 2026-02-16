package com.linksbridge.ppa.repository;

import com.linksbridge.ppa.model.Invitation;

public interface InvitationRepository extends CustomJpaRepository<Invitation, Long>
{
	Invitation findByToken(String token);

}

