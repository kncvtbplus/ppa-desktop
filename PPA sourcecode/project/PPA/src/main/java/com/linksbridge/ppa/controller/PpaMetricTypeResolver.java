package com.linksbridge.ppa.controller;

import java.util.Collection;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;

import com.linksbridge.ppa.model.MetricType;

/**
 * Resolves exported metric types without assuming that database IDs are
 * identical across PPA installations.
 */
final class PpaMetricTypeResolver
{
	private final Map<Long, MetricType> metricTypesById = new HashMap<>();
	private final Map<String, MetricType> metricTypesByKey = new HashMap<>();
	private final Map<String, MetricType> metricTypesByName = new HashMap<>();

	PpaMetricTypeResolver(Collection<MetricType> metricTypes)
	{
		if (metricTypes == null)
		{
			return;
		}

		for (MetricType metricType : metricTypes)
		{
			if (metricType == null)
			{
				continue;
			}

			if (metricType.getId() != null)
			{
				metricTypesById.put(metricType.getId(), metricType);
			}

			String normalizedKey = normalize(metricType.getRName());
			if (normalizedKey != null)
			{
				metricTypesByKey.put(normalizedKey, metricType);
			}

			String normalizedName = normalize(metricType.getName());
			if (normalizedName != null)
			{
				metricTypesByName.put(normalizedName, metricType);
			}
		}
	}

	MetricType resolve(PpaExportDto.MetricDto metricDto)
	{
		if (metricDto == null)
		{
			return null;
		}

		// Schema v2+ exports carry a stable application key plus a readable name
		// fallback. When either is present, do not fall back to a potentially
		// unrelated local database ID.
		String normalizedKey = normalize(metricDto.metricTypeKey);
		if (normalizedKey != null)
		{
			MetricType metricType = metricTypesByKey.get(normalizedKey);
			if (metricType != null)
			{
				return metricType;
			}
		}

		String normalizedName = normalize(metricDto.metricTypeName);
		if (normalizedName != null)
		{
			return metricTypesByName.get(normalizedName);
		}

		if (normalizedKey != null)
		{
			return null;
		}

		// Schema v1 only stored the database ID. Resolve it when it still exists;
		// removed legacy metric types are deliberately skipped by the importer.
		return metricDto.metricTypeId != null ? metricTypesById.get(metricDto.metricTypeId) : null;
	}

	private static String normalize(String value)
	{
		if (StringUtils.isBlank(value))
		{
			return null;
		}

		return value.trim().toLowerCase(Locale.ROOT);
	}
}
