package com.khetisahayak.filter;

import com.khetisahayak.service.JwtService;
import com.khetisahayak.service.UserService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT Authentication Filter for Kheti Sahayak Agricultural Platform
 * Validates JWT tokens for farmer authentication
 * Implements CodeRabbit security standards for agricultural user protection
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserService userService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        
        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String mobileNumber;

        // Skip JWT validation for public endpoints
        if (isPublicEndpoint(request.getRequestURI())) {
            filterChain.doFilter(request, response);
            return;
        }

        // Check if Authorization header is present and starts with "Bearer "
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            // Extract JWT token from Authorization header
            jwt = authHeader.substring(7);
            
            // Extract mobile number from JWT token
            mobileNumber = jwtService.extractUsername(jwt);
            
            // Validate token and set authentication context
            if (mobileNumber != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = userService.loadUserByUsername(mobileNumber);
                
                if (jwtService.isTokenValid(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities()
                    );
                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }
        } catch (Exception e) {
            // Log security event for invalid token
            logger.warn("Invalid JWT token for request: " + request.getRequestURI(), e);
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Check if the request URI is a public endpoint that doesn't require authentication
     */
    private boolean isPublicEndpoint(String requestURI) {
        return requestURI.equals("/") ||
               requestURI.equals("/api/health") ||
               requestURI.startsWith("/actuator/health") ||
               requestURI.startsWith("/api-docs") ||
               requestURI.startsWith("/v3/api-docs") ||
               requestURI.startsWith("/swagger-ui") ||
               requestURI.startsWith("/api/auth/login") ||
               requestURI.startsWith("/api/auth/register") ||
               requestURI.startsWith("/api/weather/public");
    }
}
