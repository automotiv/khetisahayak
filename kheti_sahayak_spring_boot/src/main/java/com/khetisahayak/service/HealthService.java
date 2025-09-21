package com.khetisahayak.service;

import com.khetisahayak.model.health.HealthCheck;
import com.khetisahayak.model.health.HealthResponse;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.lang.management.ManagementFactory;
import java.time.Instant;

@Service
public class HealthService {

    private final JdbcTemplate jdbcTemplate;
    private final RedisConnectionFactory redisConnectionFactory;

    public HealthService(JdbcTemplate jdbcTemplate, RedisConnectionFactory redisConnectionFactory) {
        this.jdbcTemplate = jdbcTemplate;
        this.redisConnectionFactory = redisConnectionFactory;
    }

    public HealthResponse getHealth() {
        boolean overallHealthy = true;
        HealthResponse resp = new HealthResponse()
                .setUptime(ManagementFactory.getRuntimeMXBean().getUptime() / 1000) // seconds
                .setTimestamp(Instant.now().toEpochMilli());

        // DB check
        try {
            Integer one = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            if (one != null && one == 1) {
                resp.addCheck(new HealthCheck("database", "OK"));
            } else {
                overallHealthy = false;
                resp.addCheck(new HealthCheck("database", "FAIL", "Unexpected query result"));
            }
        } catch (DataAccessException ex) {
            overallHealthy = false;
            resp.addCheck(new HealthCheck("database", "FAIL", ex.getMessage()));
        }

        // Redis check
        try (RedisConnection conn = redisConnectionFactory.getConnection()) {
            String pong = conn.ping();
            if (pong != null && pong.equalsIgnoreCase("PONG")) {
                resp.addCheck(new HealthCheck("redis", "OK"));
            } else {
                overallHealthy = false;
                resp.addCheck(new HealthCheck("redis", "FAIL", "PING did not return PONG"));
            }
        } catch (Exception ex) {
            overallHealthy = false;
            resp.addCheck(new HealthCheck("redis", "FAIL", ex.getMessage()));
        }

        resp.setMessage(overallHealthy ? "OK" : "Service Unavailable");
        return resp;
    }
}
