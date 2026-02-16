package com.linksbridge.thymeleaf.extras.dialect;

import java.util.HashSet;
import java.util.Set;

import org.thymeleaf.dialect.AbstractProcessorDialect;
import org.thymeleaf.processor.IProcessor;
import org.thymeleaf.standard.processor.StandardXmlNsTagProcessor;
import org.thymeleaf.templatemode.TemplateMode;

public class UnescapedDataAttributeDialect extends AbstractProcessorDialect
{
	public static final String NAMESPACE = "http://www.thymeleaf.org/extras/udata";
	public static final String PREFIX = "udata";

	public static final int PRECEDENCE = 1000;

	public UnescapedDataAttributeDialect()
	{
		super(NAMESPACE, PREFIX, PRECEDENCE);
	}

	@Override
	public Set<IProcessor> getProcessors(String dialectPrefix)
	{
		HashSet<IProcessor> processors = new HashSet<IProcessor>();
		processors.add(new StandardXmlNsTagProcessor(TemplateMode.HTML, dialectPrefix));
		processors.add(new UnescapedDataAttributeProcessor(TemplateMode.HTML, dialectPrefix));
		return processors;
	}

}

