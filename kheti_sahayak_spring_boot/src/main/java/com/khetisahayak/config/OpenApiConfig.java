package com.khetisahayak.config;

import io.swagger.v3.oas.models.ExternalDocumentation;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI khetiSahayakOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Kheti Sahayak API")
                        .version("1.0.0")
                        .description("Spring Boot backend for Kheti Sahayak, converted from Node/Express")
                        .contact(new Contact()
                                .name("Kheti Sahayak Team")
                                .url("https://github.com/automotiv/khetisahayak")))
                .externalDocs(new ExternalDocumentation()
                        .description("API Docs")
                        .url("/api-docs"));
    }
}
