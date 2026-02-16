package com.linksbridge.ppa.repository;

import java.util.Set;

import com.linksbridge.ppa.model.UserFile;

public interface UserFileRepository extends CustomJpaRepository<UserFile, Long>
{
	Set<UserFile> findByIdIn(Set<Long> userFileIds);

	Set<UserFile> findByS3FileName(String s3FileName);

	Set<UserFile> findAllByAccountIdAndFileName(Long id, String fileName);

}

