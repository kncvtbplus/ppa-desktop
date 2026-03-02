package com.linksbridge.ppa;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Runs idempotent schema migrations and data integrity checks on startup
 * that Hibernate's ddl-auto=update cannot handle.
 */
@Component
@Order(0)
public class SchemaMigrationRunner implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(SchemaMigrationRunner.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${s3.mount.host:${s3.mount}}")
    private String s3MountHost;

    @Override
    public void run(String... args) {
        widenVarcharColumnsToText();
        widenWeightMultiplierScale();
        addOutputNameColumn();
        checkUserFileIntegrity();
    }

    private void widenVarcharColumnsToText() {
        String[][] migrations = {
            {"data_source", "subnational_unit_value_frequencies"},
            {"data_source", "subnational_unit_selected_values"},
            {"data_source", "facility_type_column_values"},
            {"data_source", "facility_type_value_frequencies"},
            {"data_source", "health_sector_column_values"},
            {"data_source", "health_sector_value_frequencies"},
            {"data_source", "available_ppa_sector_mapping_value_combination_frequencies"},
            {"data_source", "subset_column1_values"},
            {"data_source", "subset_column1_value_frequencies"},
            {"data_source", "subset_column1_selected_values"},
            {"data_source", "subset_column2_values"},
            {"data_source", "subset_column2_value_frequencies"},
            {"data_source", "subset_column2_selected_values"},
            {"metric", "column_value_frequencies"},
            {"metric", "selected_column_values"},
            {"user_file", "column_names"},
            {"output", "chart_file_names"},
        };

        int altered = 0;
        for (String[] m : migrations) {
            String table = m[0];
            String column = m[1];
            try {
                String currentType = jdbcTemplate.queryForObject(
                    "SELECT data_type FROM information_schema.columns " +
                    "WHERE table_name = ? AND column_name = ?",
                    String.class, table, column);

                if (currentType != null && !"text".equals(currentType)) {
                    jdbcTemplate.execute(
                        String.format("ALTER TABLE %s ALTER COLUMN %s TYPE TEXT", table, column));
                    altered++;
                }
            } catch (Exception e) {
                logger.warn("Schema migration skipped for {}.{}: {}", table, column, e.getMessage());
            }
        }

        if (altered > 0) {
            logger.info("SchemaMigrationRunner: widened {} column(s) to TEXT.", altered);
        }
    }

    private void checkUserFileIntegrity() {
        try {
            List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT id, file_name, s3_file_name FROM user_file");

            int missing = 0;
            for (Map<String, Object> row : rows) {
                String s3Key = (String) row.get("s3_file_name");
                if (s3Key == null || s3Key.isEmpty()) continue;

                String mount = s3MountHost.endsWith("/") ? s3MountHost : s3MountHost + "/";
                Path filePath = Paths.get(mount + s3Key);
                if (!Files.exists(filePath)) {
                    missing++;
                    logger.warn("Data file missing on disk for user_file id={}, name='{}', expected path: {}",
                            row.get("id"), row.get("file_name"), filePath);
                }
            }

            if (missing > 0) {
                logger.warn("SchemaMigrationRunner: {} user file(s) have missing data on disk. " +
                        "Re-upload these files or restore from backup.", missing);
            }
        } catch (Exception e) {
            logger.warn("User file integrity check failed: {}", e.getMessage());
        }
    }

    private void addOutputNameColumn() {
        try {
            Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM information_schema.columns " +
                "WHERE table_name = 'output' AND column_name = 'name'",
                Integer.class);

            if (count == null || count == 0) {
                jdbcTemplate.execute(
                    "ALTER TABLE output ADD COLUMN name VARCHAR(255) NOT NULL DEFAULT ''");
                logger.info("SchemaMigrationRunner: added 'name' column to output table.");
            }
        } catch (Exception e) {
            logger.warn("Schema migration skipped for output.name: {}", e.getMessage());
        }
    }

    private void widenWeightMultiplierScale() {
        try {
            Integer scale = jdbcTemplate.queryForObject(
                "SELECT numeric_scale FROM information_schema.columns " +
                "WHERE table_name = 'data_source' AND column_name = 'weight_multiplier'",
                Integer.class);

            if (scale != null && scale < 12) {
                jdbcTemplate.execute(
                    "ALTER TABLE data_source ALTER COLUMN weight_multiplier TYPE numeric(19,12)");
                logger.info("SchemaMigrationRunner: widened weight_multiplier scale from {} to 12.", scale);
            }
        } catch (Exception e) {
            logger.warn("Schema migration skipped for weight_multiplier: {}", e.getMessage());
        }
    }
}
