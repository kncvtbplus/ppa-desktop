package com.linksbridge.ppa;

import java.util.Arrays;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.linksbridge.ppa.model.MetricType;
import com.linksbridge.ppa.model.PpaSectorDefaultValue;
import com.linksbridge.ppa.repository.MetricTypeRepository;
import com.linksbridge.ppa.repository.PpaSectorDefaultValueRepository;

/**
 * Seeds the bare minimum reference data needed for a completely empty local
 * database: metric types and default PPA sectors.
 *
 * This is only intended for the standalone Windows/local installer. It runs
 * safely against an existing/production database because it first checks if
 * the tables already contain any rows.
 */
@Component
public class LocalReferenceDataInitializer implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(LocalReferenceDataInitializer.class);

    @Autowired
    private MetricTypeRepository metricTypeRepository;

    @Autowired
    private PpaSectorDefaultValueRepository ppaSectorDefaultValueRepository;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        try {
            seedMetricTypesIfEmpty();
            seedPpaSectorsIfEmpty();
        } catch (DataAccessException ex) {
            // If the schema is not fully created yet we just log and continue.
            logger.warn("Skipping LocalReferenceDataInitializer because reference tables are not available yet: {}", ex.getMessage());
        }
    }

    private void seedMetricTypesIfEmpty() {
        long count = metricTypeRepository.count();
        if (count > 0) {
            return;
        }

        logger.info("No metric types found – seeding default PPA metric types for local use.");

        // Domain / region variables used to configure the PPA
        MetricType facilityType = mt("Facility Type", "domain", null, "Facility.Type", false, true,
                "", "", "");
        MetricType healthSector = mt("Health Sector", "domain", null, "Facility.Sector", false, true,
                "", "", "");
        MetricType region = mt("Region", "region", null, "Region", false, true,
                "", "", "");

        // Core patient pathway metrics – required for the visualisations
        MetricType numberOfFacilities = mt("Number of Facilities", "variable", null, "N.Facilities",
                true, false, "N.Facilities", "", "");
        MetricType careSeeking = mt("Care Seeking", "variable", null, "Care.Seeking",
                true, false, "Care.Seeking", "", "");

        MetricType dx1 = mt("Diagnostic Availability 1", "variable", null, "Dx.Availability.1",
                false, true, "", "Diagnostic.1.Availability", "Diagnostic.1.Access");
        MetricType dx2 = mt("Diagnostic Availability 2", "variable", null, "Dx.Availability.2",
                false, true, "", "Diagnostic.2.Availability", "Diagnostic.2.Access");
        MetricType dx3 = mt("Diagnostic Availability 3", "variable", null, "Dx.Availability.3",
                false, true, "", "Diagnostic.3.Availability", "Diagnostic.3.Access");
        MetricType dx4 = mt("Diagnostic Availability 4", "variable", null, "Dx.Availability.4",
                false, true, "", "Diagnostic.4.Availability", "Diagnostic.4.Access");

        MetricType tx1 = mt("Treatment Availability 1", "variable", null, "Tx.Availability.1",
                false, true, "", "Treatment.1.Availability", "Treatment.1.Access");
        MetricType tx2 = mt("Treatment Availability 2", "variable", null, "Tx.Availability.2",
                false, true, "", "Treatment.2.Availability", "Treatment.2.Access");
        MetricType tx3 = mt("Treatment Availability 3", "variable", null, "Tx.Availability.3",
                false, true, "", "Treatment.3.Availability", "Treatment.3.Access");
        MetricType tx4 = mt("Treatment Availability 4", "variable", null, "Tx.Availability.4",
                false, true, "", "Treatment.4.Availability", "Treatment.4.Access");

        MetricType notificationLocation = mt("Notification Location", "variable", null, "Notification.Location",
                false, true, "", "", "");
        MetricType treatmentLocation = mt("Treatment Location", "variable", null, "Tx.Location",
                false, true, "", "", "");
        MetricType treatmentOutcome = mt("Treatment Outcome", "variable", null, "Tx.Outcome",
                false, true, "", "", "");

        List<MetricType> all = Arrays.asList(
                facilityType,
                healthSector,
                region,
                numberOfFacilities,
                careSeeking,
                dx1, dx2, dx3, dx4,
                tx1, tx2, tx3, tx4,
                notificationLocation,
                treatmentLocation,
                treatmentOutcome
        );

        metricTypeRepository.saveAll(all);
        logger.info("Seeded {} metric types.", all.size());
    }

    private MetricType mt(String name,
                          String type,
                          String subtype,
                          String rName,
                          boolean required,
                          boolean columnValueFilter,
                          String rHeader,
                          String rHeaderAvailability,
                          String rHeaderAccess) {
        MetricType mt = new MetricType();
        mt.setName(name);
        mt.setType(type);
        mt.setSubtype(subtype);
        mt.setRName(rName);
        mt.setRequired(required);
        mt.setColumnValueFilter(columnValueFilter);
        mt.setRHeader(rHeader);
        mt.setRHeaderAvailability(rHeaderAvailability);
        mt.setRHeaderAccess(rHeaderAccess);
        return mt;
    }

    private void seedPpaSectorsIfEmpty() {
        long count = ppaSectorDefaultValueRepository.count();
        if (count > 0) {
            return;
        }

        logger.info("No PPA sector default values found – seeding defaults for local use.");

        PpaSectorDefaultValue publicSector = sector(1, "Public", false);
        PpaSectorDefaultValue privateSector = sector(2, "Private", false);
        PpaSectorDefaultValue informalPrivate = sector(3, "Informal Private", false);
        PpaSectorDefaultValue custom = sector(4, "Enter Custom Sector", true);

        ppaSectorDefaultValueRepository.saveAll(Arrays.asList(
                publicSector, privateSector, informalPrivate, custom
        ));
        logger.info("Seeded default PPA sectors.");
    }

    private PpaSectorDefaultValue sector(long position, String name, boolean editable) {
        PpaSectorDefaultValue v = new PpaSectorDefaultValue();
        v.setPosition(position);
        v.setName(name);
        v.setEditable(editable);
        return v;
    }
}


