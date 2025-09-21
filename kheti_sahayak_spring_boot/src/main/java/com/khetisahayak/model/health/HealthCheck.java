package com.khetisahayak.model.health;

public class HealthCheck {
    private String name;
    private String status;
    private String error;

    public HealthCheck() {}

    public HealthCheck(String name, String status) {
        this.name = name;
        this.status = status;
    }

    public HealthCheck(String name, String status, String error) {
        this.name = name;
        this.status = status;
        this.error = error;
    }

    public String getName() {
        return name;
    }

    public HealthCheck setName(String name) {
        this.name = name;
        return this;
    }

    public String getStatus() {
        return status;
    }

    public HealthCheck setStatus(String status) {
        this.status = status;
        return this;
    }

    public String getError() {
        return error;
    }

    public HealthCheck setError(String error) {
        this.error = error;
        return this;
    }
}
