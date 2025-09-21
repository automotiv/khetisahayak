package com.khetisahayak.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;

/**
 * Security configuration for Kheti Sahayak agricultural platform
 * Implements role-based access control for farmers, experts, and administrators
 * Follows CodeRabbit security standards for agricultural data protection
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
            // Disable CSRF for stateless JWT APIs
            .csrf(csrf -> csrf.disable())
            
            // Configure CORS for agricultural platform
            .cors(Customizer.withDefaults())
            
            // Stateless session management for JWT
            .sessionManagement(session -> 
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            
            // Security headers for farmer data protection
            .headers(headers -> headers
                .xssProtection(Customizer.withDefaults())
                .frameOptions(frame -> frame.sameOrigin())
                .contentSecurityPolicy(csp -> csp.policyDirectives(
                    "default-src 'self'; " +
                    "img-src 'self' data: https:; " +
                    "script-src 'self'; " +
                    "style-src 'self' 'unsafe-inline'"
                ))
                .referrerPolicy(ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN)
                .httpStrictTransportSecurity(hstsConfig -> hstsConfig
                    .maxAgeInSeconds(31536000)
                    .includeSubdomains(true)
                )
            )
            
            // Role-based authorization for agricultural platform
            .authorizeHttpRequests(auth -> auth
                // Public endpoints - no authentication required
                .requestMatchers("/", "/api/health", "/actuator/health").permitAll()
                .requestMatchers("/api-docs/**", "/v3/api-docs/**", "/swagger-ui/**").permitAll()
                .requestMatchers("/api/auth/login", "/api/auth/register").permitAll()
                .requestMatchers("/api/weather/public").permitAll() // Public weather data
                
                // Farmer endpoints - require FARMER role
                .requestMatchers("/api/diagnostics/**").hasRole("FARMER")
                .requestMatchers("/api/weather/**").hasRole("FARMER")
                .requestMatchers("/api/marketplace/**").hasRole("FARMER")
                .requestMatchers("/api/education/**").hasRole("FARMER")
                .requestMatchers("/api/community/**").hasRole("FARMER")
                .requestMatchers("/api/schemes/**").hasRole("FARMER")
                .requestMatchers("/api/profile/**").hasRole("FARMER")
                
                // Expert endpoints - require EXPERT role
                .requestMatchers("/api/expert/**").hasRole("EXPERT")
                .requestMatchers("/api/diagnostics/*/expert-review").hasRole("EXPERT")
                .requestMatchers("/api/consultations/**").hasRole("EXPERT")
                
                // Admin endpoints - require ADMIN role
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/users/**").hasRole("ADMIN")
                .requestMatchers("/api/analytics/**").hasRole("ADMIN")
                .requestMatchers("/actuator/**").hasRole("ADMIN")
                
                // All other requests require authentication
                .anyRequest().authenticated()
            )
            
            // JWT resource server configuration (to be implemented)
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            
            .build();
    }
}
