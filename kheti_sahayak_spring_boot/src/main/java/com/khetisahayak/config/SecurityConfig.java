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
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.khetisahayak.filter.JwtAuthenticationFilter;
import com.khetisahayak.service.JwtService;
import com.khetisahayak.service.UserService;

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
    public SecurityFilterChain securityFilterChain(HttpSecurity http, JwtService jwtService, UserService userService) throws Exception {
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
                .referrerPolicy(referrer -> referrer
                    .policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN)
                )
            )
            
            // Role-based authorization for agricultural platform
            .authorizeHttpRequests(auth -> auth
                // Public endpoints - no authentication required
                .requestMatchers("/", "/api/health", "/actuator/health").permitAll()
                .requestMatchers("/api-docs/**", "/v3/api-docs/**", "/swagger-ui/**").permitAll()
                .requestMatchers("/api/auth/login", "/api/auth/register").permitAll()
                .requestMatchers("/api/weather/public").permitAll() // Public weather data
                .requestMatchers(HttpMethod.GET, "/api/weather", "/api/weather/**").permitAll()
                
                // Public access to educational content (read-only)
                .requestMatchers(HttpMethod.GET, "/api/education/content/**", "/api/education/categories").permitAll()
                
                // Public access to schemes (read-only)
                .requestMatchers(HttpMethod.GET, "/api/schemes", "/api/schemes/**").permitAll()
                
                // Farmer endpoints - require FARMER role
                .requestMatchers("/api/diagnostics/**").hasRole("FARMER")
                .requestMatchers(HttpMethod.POST, "/api/weather/**").hasRole("FARMER")
                .requestMatchers("/api/marketplace/**").hasRole("FARMER")
                .requestMatchers("/api/education/**").hasRole("FARMER")
                .requestMatchers("/api/notifications/**").hasRole("FARMER")
                .requestMatchers("/api/community/**").hasRole("FARMER")
                .requestMatchers("/api/schemes/applications/**").hasRole("FARMER")
                .requestMatchers("/api/experts/**").hasRole("FARMER")
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
            
            // JWT authentication filter
            .addFilterBefore(jwtAuthenticationFilter(jwtService, userService), UsernamePasswordAuthenticationFilter.class)
            
            .build();
    }

    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter(JwtService jwtService, UserService userService) {
        return new JwtAuthenticationFilter(jwtService, userService);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationProvider authenticationProvider(UserDetailsService userDetailsService, PasswordEncoder passwordEncoder) {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder);
        return authProvider;
    }
}
