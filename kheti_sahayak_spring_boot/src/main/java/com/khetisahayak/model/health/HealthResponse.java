package com.khetisahayak.model.health;

import java.util.ArrayList;
import java.util.List;

public class HealthResponse {
    private long uptime;
    private String message;
    private long timestamp;
    private List<HealthCheck> checks = new ArrayList<>();

    public HealthResponse() {}

    public long getUptime() {
        return uptime;
    }

    public HealthResponse setUptime(long uptime) {
        this.uptime = uptime;
        return this;
    }

    public String getMessage() {
        return message;
    }

    public HealthResponse setMessage(String message) {
        this.message = message;
        return this;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public HealthResponse setTimestamp(long timestamp) {
        this.timestamp = timestamp;
        return this;
    }

    public List<HealthCheck> getChecks() {
        return checks;
    }

    public HealthResponse setChecks(List<HealthCheck> checks) {
        this.checks = checks;
        return this;
    }

    public HealthResponse addCheck(HealthCheck check) {
        this.checks.add(check);
        return this;
    }
}
