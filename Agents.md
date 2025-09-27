# Software Platform - Development Standards

## 🚀 Using CodeRabbit for Development

Always use CodeRabbit for:
- Automated code reviews and suggestions
- Enforcing coding standards and best practices
- Detecting bugs, vulnerabilities, and anti-patterns
- Generating documentation and code comments
- Refactoring and improving code quality
- Reviewing pull requests before merging

**Instruction:**
> Every developer must run CodeRabbit on all new code, changes, and pull requests. Address all issues and suggestions raised by CodeRabbit before finalizing any code merge or deployment.

---

This document defines the coding standards and best practices for building scalable, maintainable, and adaptable software platforms.

## 🏗️ **Platform Architecture Principles**

### **Universal Platform Vision**
- **Multi-Domain Support:** Every feature must be designed to work across different business domains.
- **Category Agnostic:** Features should be universally applicable and not tied to a specific domain.
- **Scalable Design:** Architecture must support rapid expansion to new domains or use cases.
- **Consistent Experience:** Maintain uniform user experience across all platform modules.

### **Environment-First Development**
- **Environment Separation:** Clear separation between local, development, staging, and production environments.
- **Configuration Externalization:** All environment-specific settings must be externalized.
- **Cloud Ready:** Native support for cloud services and integrations.
- **Security by Design:** No hardcoded credentials, proper secret management.

## 📜 **Code Readability and Style**

* **Clarity over cleverness:** Write code that is easy to understand, even if it's not the shortest possible solution.
* **Meaningful Names:** Use descriptive names for variables, functions, and classes. A good name should explain its purpose without needing extra comments.
* **Consistency:** Adhere to a consistent coding style throughout the project (e.g., variable naming, indentation, brace placement). Use a linter to enforce style rules automatically.
* **Domain-Driven Naming:** Use terminology that reflects the platform's vocabulary.

***

## 🧱 **SOLID Principles for Software Platforms**

The SOLID principles are essential for building maintainable, scalable platforms that can serve multiple domains effectively.

### **S - Single Responsibility Principle (SRP)**

* **A class should have one, and only one, reason to change.**
* **Application:** Each service should handle one specific capability (e.g., catalog management, order processing, payment handling)
* **Domain Agnostic Design:** Services should not be tied to specific domains but should be universally applicable
* **File Structure:** If a class's length is increasing, it's a strong indicator that it's taking on too many responsibilities. Refactor these responsibilities into new, focused classes, and place each new class in its own file.
* **Example:** `FeedService` should only handle feed generation logic, while `UniversalFeedService` should handle common feed logic.

### **O - Open/Closed Principle (OCP)**

* **Software entities should be open for extension but closed for modification.**
* **Platform Extensibility:** New domains should be added without modifying existing core platform code
* **Feature Extensions:** New features should be pluggable into the existing platform architecture
* **Implementation:** Use interfaces and abstract classes to define contracts that can be extended for new domains
* **Example:** `FeedPublisher` interface can be extended for new domains without modifying existing implementations.

### **L - Liskov Substitution Principle (LSP)**

* **Objects of a superclass should be replaceable with objects of its subclasses without affecting the correctness of the program.**
* **Domain Interchangeability:** Any domain-specific implementation should be replaceable with another without breaking the platform
* **Service Substitution:** Platform services should work consistently regardless of the specific domain implementation
* **Example:** Any `DomainFeedService` implementation should work seamlessly with the `UniversalFeedProcessor`.

### **I - Interface Segregation Principle (ISP)**

* **Clients should not be forced to depend on interfaces they do not use.**
* **Domain-Specific Interfaces:** Create specific interfaces for each domain's unique requirements
* **Platform Interfaces:** Keep platform-level interfaces focused on common functionality
* **Example:** `CatalogService` should not depend on unrelated domain interfaces.

### **D - Dependency Inversion Principle (DIP)**

* **High-level modules should not depend on low-level modules. Both should depend on abstractions.**
* **Platform Independence:** High-level platform services should not depend on specific domain implementations
* **Cloud Service Abstraction:** Platform should depend on cloud service abstractions, not specific implementations
* **Configuration Abstraction:** Services should depend on configuration abstractions, not specific environment implementations
* **Example:** `FeedProcessor` should depend on `ConfigurationService` interface, not specific YAML or properties implementations.
 
***
 
## ✍️ **Documentation Standards for Software Platforms**

### **API Documentation**
* **OpenAPI/Swagger:** All REST APIs must be documented with OpenAPI 3.0 specifications
* **Domain-Specific APIs:** Document APIs that are specific to business domains separately
* **Platform APIs:** Document common platform APIs that work across all domains
* **Integration Documentation:** Document all external service integrations (e.g., Azure Service Bus, Kafka, Cosmos DB)

### **Code Documentation**
* **Why, not What:** Comments should explain *why* a piece of code exists, its design choices, or complex business logic. The code itself should explain *what* it does.
* **Business Context:** Document business rules and domain-specific logic clearly
* **Class and Method-Level Comments:** Every class and public method should have JavaDoc explaining its purpose, arguments, return values, and any exceptions it might raise.
* **Configuration Documentation:** Document all environment-specific configurations and their purposes
* **Integration Points:** Document all external service integration points and their contracts

### **Architecture Documentation**
* **Platform Architecture:** Document the overall platform architecture and how different domains integrate
* **Service Dependencies:** Document service dependencies and data flow
* **Environment Configuration:** Document environment setup and configuration management
* **Deployment Documentation:** Document deployment procedures for different environments
 
***
 
## 🛡️ **Defensive Coding for Enterprise Platforms**

### **Error Handling and Resilience**
* **Graceful Degradation:** Implement circuit breakers and fallback mechanisms for external service failures
* **Retry Logic:** Implement exponential backoff for transient failures in cloud services
* **Error Boundaries:** Use proper error boundaries to prevent cascading failures across domains
* **Logging and Monitoring:** Implement comprehensive logging for debugging and monitoring across all environments

### **Input Validation and Security**
* **Input Sanitization:** Validate and sanitize all inputs, especially for multi-tenant scenarios
* **Business Rule Validation:** Implement validation for business rules specific to each domain
* **Data Privacy:** Ensure compliance with data privacy regulations across all domains
* **Security Headers:** Implement proper security headers for all APIs

### **Testing Strategy**
* **Unit Testing:** Write comprehensive unit tests for all business logic
* **Integration Testing:** Test integration with cloud services (e.g., Service Bus, Cosmos DB, Event Hubs)
* **Domain Testing:** Test functionality across all business domains
* **Environment Testing:** Test in all environments (local, dev, sit, prod)
* **Performance Testing:** Load test the platform for multi-domain scenarios
 
## ☁️ **Cloud and Environment Configuration Standards**

### **Environment Management**
* **Profile-Based Configuration:** Use Spring profiles (local, dev, sit, prod) for environment-specific configurations
* **Externalized Configuration:** All sensitive data must be externalized using environment variables
* **Cloud Integration:** Leverage cloud provider's secret management for production secret management
* **Configuration Validation:** Implement startup validation to ensure all required environment variables are present

### **Cloud Service Integration**
* **Service Bus:** Use cloud-native service bus for event processing with proper error handling
* **Cosmos DB:** Implement proper connection pooling and retry logic for Cosmos DB
* **Event Hubs/Kafka:** Use cloud-native event hubs or Kafka for message streaming
* **Monitoring:** Implement cloud provider's monitoring solutions for comprehensive monitoring

### **Security Best Practices**
* **No Hardcoded Credentials:** Never commit credentials to version control
* **Environment-Specific Secrets:** Use different secrets for each environment
* **Cloud RBAC:** Implement proper role-based access control for cloud resources
* **Network Security:** Use cloud provider's virtual networks and security groups appropriately

## 🔧 **Development Workflow Standards**

### **Code Quality and Standards**
* **Static Analysis:** Use Checkstyle, SpotBugs, and PMD for Java code quality
* **Code Reviews:** Mandatory code reviews for all changes
* **Automated Testing:** CI/CD pipeline must include automated testing
* **Environment Parity:** Maintain consistency between local, dev, sit, and prod environments

### **Git and Version Control**
* **Branch Strategy:** Use feature branches with proper naming conventions
* **Commit Messages:** Follow conventional commit format with proper prefixes
* **Pull Requests:** All changes must go through pull request process
* **Release Management:** Use semantic versioning for releases

### **Development Responsibilities**
- Break complex engineering tasks into simple, manageable steps
- Format all tool use in XML format for consistency
- Never assume tool success - always verify results
- Always confirm changes or outputs with the user
- Never combine tool calls - execute them individually
- Follow best practices for readability, modularity, and testability
- Treat user workspace as production-level environment
- Generate and work through solutions systematically until tasks are completed
 
## 🏪 **Platform Specific Guidelines**

### **Multi-Domain Architecture**
* **Domain Abstraction:** Design services to be domain-agnostic where possible
* **Domain-Specific Logic:** Isolate domain-specific business logic in dedicated services
* **Common Platform Services:** Build reusable services for common functionality
* **Data Model Design:** Design data models to support multiple domains with proper categorization

### **Business Domain Considerations**
* **Fashion:** Product variants, size charts, seasonal collections
* **Healthcare:** Prescription validation, drug interactions, regulatory compliance
* **Luxury:** Certificate validation, precious metal pricing, authentication
* **Grocery:** Perishable goods, inventory management, delivery scheduling
* **Electronics:** Technical specifications, warranty management, compatibility
* **Mobile:** Device specifications, carrier compatibility, activation processes

### **Performance and Scalability**
* **Multi-Tenant Architecture:** Design for multiple domains sharing the same platform
* **Caching Strategy:** Implement appropriate caching for different vertical requirements
* **Database Optimization:** Optimize queries for multi-domain data access patterns
* **Load Balancing:** Design for varying load patterns across different domains

### **Integration Standards**
* **External Service Integration:** Standardize integration patterns for external services
* **API Gateway:** Use API gateway for consistent API management across domains
* **Event-Driven Architecture:** Implement event-driven patterns for loose coupling
* **Data Synchronization:** Ensure data consistency across domains and external systems

## 📋 **Commit Message Standards**

### **Conventional Commit Format**
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### **Commit Types**
- `feat:` - New features for the platform
- `fix:` - Bug fixes
- `perf:` - Performance improvements
- `docs:` - Documentation changes
- `style:` - Code formatting changes
- `refactor:` - Code refactoring without changing functionality
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks, dependency updates
- `config:` - Configuration changes
- `env:` - Environment-specific changes

### **Scope Examples**
- `catalog` - Catalog service changes
- `feed` - Feed generation changes
- `config` - Configuration changes
- `azure` - Azure service integration changes
- `vertical` - Vertical-specific changes

### **Examples**
```
feat(catalog): add multi-domain product support
fix(azure): resolve Service Bus connection timeout
docs(config): update environment setup guide
refactor(feed): extract common feed generation logic
```

## 🚀 **Deployment and Environment Management**

### **Environment-Specific Deployment**
* **Local Development:** Use local services with environment variables
* **Azure Dev:** Deploy to Azure development environment with dev-specific configurations
* **Azure SIT:** Deploy to Azure SIT environment for integration testing
* **Azure Production:** Deploy to Azure production environment with production configurations

### **CI/CD Pipeline Requirements**
* **Automated Testing:** Unit, integration, and end-to-end tests
* **Code Quality Gates:** Static analysis, security scanning, dependency checks
* **Environment Validation:** Validate configuration before deployment
* **Rollback Strategy:** Implement automated rollback for failed deployments
* **Monitoring Integration:** Deploy with proper monitoring and alerting

## 📚 **Reference Documentation**

### **Platform Documentation**
* **Architecture Overview:** High-level platform architecture and design decisions
* **Service Catalog:** Documentation of all platform services and their capabilities
* **API Documentation:** OpenAPI specifications for all REST APIs
* **Integration Guide:** How to integrate with external services and systems

### **Domain-Specific Documentation**
* **Business Rules:** Document business rules specific to each domain
* **Data Models:** Document data models and their relationships
* **Integration Points:** Document how each domain integrates with the platform
* **Configuration Guide:** Environment-specific configuration documentation

### **Development Resources**
* **Azure Documentation:** Microsoft Azure service documentation
* **Spring Boot Documentation:** Spring Boot framework documentation
* **Kafka Documentation:** Apache Kafka documentation for message streaming
* **MongoDB Documentation:** MongoDB and Cosmos DB documentation
 
## 🎯 **Platform Vision and Goals**

### **Unified Commerce Platform Mission**
We are building a unified commerce platform that serves multiple business verticals:

- **Fashion and lifestyle e-commerce**
- **Healthcare and pharmaceutical services**  
- **Luxury jewelry and precious metals**
- **Grocery and daily essentials**
- **Electronics and technology products**
- **Mobile devices and telecommunications**

### **Platform Objectives**
- **Universal Features:** Every feature developed should be available for every category
- **Scalable Architecture:** Support rapid expansion to new verticals and markets
- **Consistent Experience:** Maintain uniform user experience across all platforms
- **Operational Excellence:** Ensure high availability, performance, and reliability

### **Starting Point: Catalog Service**
The catalog service is the foundation of our unified commerce platform, providing:
- Multi-vertical product management
- Universal product data model
- Cross-vertical search and discovery
- Integration with all business verticals

## 🔧 **Development Tools and Automation**

### **Windsurf Integration**
- Automatically suggest additions for `.windsurf` files where best practices are used
- When uncertain about rules, ask the user for clarification
- Maintain consistency with platform standards across all development tools

### **Code Quality Automation**
- **Static Analysis:** Automated code quality checks using Checkstyle, SpotBugs, PMD
- **Security Scanning:** Automated security vulnerability scanning
- **Dependency Management:** Automated dependency updates and vulnerability checks
- **Performance Monitoring:** Automated performance regression detection

## 📈 **Success Metrics**

### **Technical Metrics**
- **Code Coverage:** Maintain >80% test coverage across all services
- **Performance:** Sub-200ms response times for catalog operations
- **Availability:** 99.9% uptime across all environments
- **Security:** Zero critical security vulnerabilities

### **Business Metrics**
- **Vertical Adoption:** Successful deployment across all business domains
- **Feature Reusability:** >70% of features reusable across domains
- **Development Velocity:** Reduced time-to-market for new vertical features
- **Operational Efficiency:** Reduced maintenance overhead through unified platform

## 🎉 **Conclusion**

This document serves as the foundation for building a world-class unified commerce platform that will power digital transformation across multiple business verticals. By following these standards and principles, we ensure:

- **Consistent Quality:** High-quality, maintainable code across all services
- **Scalable Growth:** Platform that can grow with business needs
- **Team Collaboration:** Clear standards that enable effective team collaboration
- **Business Success:** Technical excellence that drives business value

**Thank you for your contribution to building the future of unified commerce!**

---

*This document is a living guide that evolves with our platform. Please contribute improvements and updates as we learn and grow together.*