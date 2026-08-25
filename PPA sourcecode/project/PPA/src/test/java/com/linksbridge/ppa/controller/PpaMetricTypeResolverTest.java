package com.linksbridge.ppa.controller;

import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;

import java.util.Arrays;

import org.junit.jupiter.api.Test;

import com.linksbridge.ppa.model.MetricType;

class PpaMetricTypeResolverTest
{
	@Test
	void resolvesLegacySchemaMetricByExistingId()
	{
		MetricType diagnostic = metricType(6L, "Diagnostic 1");
		PpaMetricTypeResolver resolver = new PpaMetricTypeResolver(Arrays.asList(diagnostic));
		PpaExportDto.MetricDto exportedMetric = new PpaExportDto.MetricDto();
		exportedMetric.metricTypeId = 6L;

		assertSame(diagnostic, resolver.resolve(exportedMetric));
	}

	@Test
	void skipsRemovedLegacySchemaMetricId()
	{
		PpaMetricTypeResolver resolver =
				new PpaMetricTypeResolver(Arrays.asList(metricType(6L, "Diagnostic 1")));
		PpaExportDto.MetricDto exportedMetric = new PpaExportDto.MetricDto();
		exportedMetric.metricTypeId = 1L;

		assertNull(resolver.resolve(exportedMetric));
	}

	@Test
	void resolvesCurrentSchemaMetricByStableKeyWhenIdsAndNamesDiffer()
	{
		MetricType diagnostic = metricType(106L, "New diagnostic label");
		diagnostic.setRName("Dx.Availability.1");
		PpaMetricTypeResolver resolver = new PpaMetricTypeResolver(Arrays.asList(diagnostic));
		PpaExportDto.MetricDto exportedMetric = new PpaExportDto.MetricDto();
		exportedMetric.metricTypeId = 6L;
		exportedMetric.metricTypeKey = " dx.availability.1 ";
		exportedMetric.metricTypeName = "Old diagnostic label";

		assertSame(diagnostic, resolver.resolve(exportedMetric));
	}

	@Test
	void resolvesCurrentSchemaMetricByNameWhenKeyIsUnavailable()
	{
		MetricType diagnostic = metricType(106L, "Diagnostic 1");
		PpaMetricTypeResolver resolver = new PpaMetricTypeResolver(Arrays.asList(diagnostic));
		PpaExportDto.MetricDto exportedMetric = new PpaExportDto.MetricDto();
		exportedMetric.metricTypeId = 6L;
		exportedMetric.metricTypeName = " diagnostic 1 ";

		assertSame(diagnostic, resolver.resolve(exportedMetric));
	}

	@Test
	void doesNotUsePotentiallyUnrelatedIdWhenSemanticReferenceIsUnknown()
	{
		PpaMetricTypeResolver resolver =
				new PpaMetricTypeResolver(Arrays.asList(metricType(6L, "Diagnostic 1")));
		PpaExportDto.MetricDto exportedMetric = new PpaExportDto.MetricDto();
		exportedMetric.metricTypeId = 6L;
		exportedMetric.metricTypeName = "Removed metric";

		assertNull(resolver.resolve(exportedMetric));
	}

	private MetricType metricType(Long id, String name)
	{
		MetricType metricType = new MetricType();
		metricType.setId(id);
		metricType.setName(name);
		return metricType;
	}
}
