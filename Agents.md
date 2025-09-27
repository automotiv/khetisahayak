# Kheti Sahayak - Development Standards & Agent Instructions

## 🌾 **Project Overview**
Kheti Sahayak is a comprehensive digital agricultural platform designed to empower farmers with modern technology solutions for crop management, market access, and agricultural expertise.

### **Core Mission**
- **Digital Agriculture Transformation:** Modernizing traditional farming practices through technology
- **Farmer Empowerment:** Providing tools for better crop management and market access
- **Sustainable Farming:** Promoting environmentally conscious agricultural practices
- **Rural Development:** Bridging the digital divide in agricultural communities

## 🚀 **CodeRabbit Integration & Code Quality Standards**

### **Mandatory CodeRabbit Usage**
Always use CodeRabbit for:
- **Automated code reviews** and intelligent suggestions
- **Agricultural domain-specific** code analysis
- **Security vulnerabilities** detection for farmer data protection
- **Performance optimization** for mobile and rural connectivity
- **Accessibility compliance** for diverse user capabilities
- **API consistency** across Spring Boot backend services
- **Database query optimization** for agricultural data
- **Mobile responsiveness** validation for Flutter/React applications

**Critical Instruction:**
> Every developer MUST run CodeRabbit analysis on all code changes. Address ALL issues related to:
> 1. **Data Privacy:** Farmer information security
> 2. **Mobile Performance:** Optimized for low-bandwidth rural networks  
> 3. **Accessibility:** WCAG 2.1 AA compliance for inclusive design
> 4. **API Security:** Spring Boot endpoint protection
> 5. **Database Efficiency:** Agricultural data query optimization

### **CodeRabbit Implementation Workflow**

#### **Step 1: Setup CodeRabbit Integration**
1. **GitHub Integration:**
   ```bash
   # Visit https://www.coderabbit.ai/
   # Sign up with GitHub account
   # Authorize access to khetisahayak repository
   # Enable automatic PR reviews
   ```

2. **Configuration File:** (Already created at `.coderabbit.yaml`)
   ```yaml
   # Kheti Sahayak specific configuration
   language: "typescript"
   framework: "react"
   backend: "spring-boot"
   focus:
     - "security"
     - "performance" 
     - "accessibility"
     - "agricultural-domain"
   ```

#### **Step 2: Mandatory Pre-Commit Analysis**
**EVERY developer must run these commands before committing:**

```bash
# 1. Install pr-vibe for CodeRabbit integration
npm install -g pr-vibe

# 2. Initialize CodeRabbit patterns for agricultural domain
pr-vibe init-patterns

# 3. Run analysis on current changes
git add .
git diff --cached | pr-vibe analyze --agricultural-context

# 4. Address ALL issues before committing
# - Security vulnerabilities (CRITICAL)
# - Performance issues (HIGH)
# - Accessibility violations (HIGH)
# - Agricultural domain violations (MEDIUM)
```

#### **Step 3: Pull Request CodeRabbit Review**
**For EVERY pull request:**

1. **Create PR with CodeRabbit auto-review:**
   ```bash
   # Push branch
   git push origin feature/your-feature-name
   
   # Create PR - CodeRabbit will auto-review
   # Wait for CodeRabbit analysis (usually 2-3 minutes)
   ```

2. **Address CodeRabbit Comments:**
   - **CRITICAL Issues:** Must be fixed before merge
   - **HIGH Issues:** Must be fixed or justified
   - **MEDIUM Issues:** Should be addressed
   - **LOW Issues:** Can be addressed in future PRs

3. **CodeRabbit Commands in PR:**
   ```bash
   # Generate docstrings for functions
   @coderabbitai generate docstrings
   
   # Ask specific questions
   @coderabbitai explain this agricultural logic
   
   # Request security review
   @coderabbitai review security implications
   
   # Check accessibility compliance
   @coderabbitai check accessibility
   ```

#### **Step 4: Agricultural Domain-Specific Checks**
**CodeRabbit must validate these Kheti Sahayak specific requirements:**

1. **Crop Data Validation:**
   ```typescript
   // CodeRabbit should flag missing validation
   interface CropData {
     type: string;        // ❌ Should validate against known crop types
     season: string;      // ❌ Should validate Kharif/Rabi/Zaid
     region: string;      // ❌ Should validate Indian states/regions
   }
   
   // ✅ Correct implementation
   interface CropData {
     type: CropType;      // Enum with valid crops
     season: Season;      // Enum with Indian seasons
     region: IndianRegion; // Enum with states/regions
   }
   ```

2. **Weather Data Security:**
   ```java
   // ❌ CodeRabbit should flag this
   @GetMapping("/weather")
   public WeatherData getWeather(@RequestParam String location) {
     // No validation - security risk
   }
   
   // ✅ CodeRabbit approved
   @GetMapping("/weather")
   public WeatherData getWeather(
     @Valid @Pattern(regexp = "^[0-9.-]+,[0-9.-]+$") String coordinates
   ) {
     // Validated coordinates only
   }
   ```

3. **Farmer Data Privacy:**
   ```typescript
   // ❌ CodeRabbit should flag this
   const farmerData = {
     name: "John Doe",
     location: "exact GPS coordinates", // Privacy violation
     income: 50000                      // Sensitive data
   };
   
   // ✅ CodeRabbit approved
   const farmerData = {
     farmerId: hashId(farmer.id),       // Anonymized
     region: generalizeLocation(coords), // Generalized location
     incomeRange: getIncomeRange(income) // Categorized data
   };
   ```

#### **Step 5: Performance Optimization for Rural Networks**
**CodeRabbit must check for rural connectivity optimizations:**

1. **Image Compression:**
   ```typescript
   // ❌ CodeRabbit should flag
   const uploadImage = (file: File) => {
     // No compression - will fail on 2G networks
     return api.post('/upload', file);
   };
   
   // ✅ CodeRabbit approved
   const uploadImage = async (file: File) => {
     const compressed = await compressForRural(file, {
       maxSize: 500 * 1024,    // 500KB max
       quality: 0.7,           // 70% quality
       maxDimensions: [800, 600] // Reasonable size
     });
     return api.post('/upload', compressed);
   };
   ```

2. **Offline Support:**
   ```typescript
   // ❌ CodeRabbit should flag missing offline support
   const getCropRecommendations = async (cropType: string) => {
     return api.get(`/recommendations/${cropType}`); // Fails offline
   };
   
   // ✅ CodeRabbit approved
   const getCropRecommendations = async (cropType: string) => {
     try {
       return await api.get(`/recommendations/${cropType}`);
     } catch (error) {
       return getOfflineRecommendations(cropType); // Offline fallback
     }
   };
   ```

#### **Step 6: Accessibility Compliance (WCAG 2.1 AA)**
**CodeRabbit must verify accessibility for rural farmers:**

1. **Screen Reader Support:**
   ```tsx
   {/* ❌ CodeRabbit should flag */}
   <button onClick={diagnoseCrop}>
     <img src="crop-icon.png" />
   </button>
   
   {/* ✅ CodeRabbit approved */}
   <button 
     onClick={diagnoseCrop}
     aria-label="Diagnose crop health using image analysis"
     aria-describedby="crop-diagnosis-help"
   >
     <img src="crop-icon.png" alt="Crop diagnosis icon" />
   </button>
   <div id="crop-diagnosis-help" className="sr-only">
     Upload a photo of your crop to get instant health analysis and treatment recommendations
   </div>
   ```

2. **Multi-language Support:**
   ```typescript
   // ❌ CodeRabbit should flag hardcoded English
   const message = "Your crop is healthy";
   
   // ✅ CodeRabbit approved
   const message = t('crop.health.healthy', {
     defaultValue: 'Your crop is healthy',
     context: 'agricultural'
   });
   ```

### **CodeRabbit Enforcement Rules**

#### **Blocking Conditions (PR Cannot Merge):**
1. **CRITICAL Security Issues:** Any vulnerability affecting farmer data
2. **Missing Input Validation:** All API endpoints must validate inputs
3. **Accessibility Violations:** WCAG 2.1 AA compliance required
4. **Performance Issues:** Any code that would fail on 2G networks
5. **Agricultural Logic Errors:** Incorrect crop/weather/season logic

#### **Warning Conditions (Requires Justification):**
1. **Performance Optimizations:** Suggested improvements for rural networks
2. **Code Duplication:** Repeated agricultural logic should be abstracted
3. **Documentation:** Missing JSDoc for agricultural domain functions
4. **Testing:** Missing tests for critical farming workflows

#### **CodeRabbit Quality Gates:**
```yaml
# Quality thresholds that must be met
quality_gates:
  security_score: 9/10      # High security for farmer data
  performance_score: 8/10   # Optimized for rural networks
  accessibility_score: 9/10 # WCAG 2.1 AA compliance
  maintainability: 8/10     # Clean, readable code
  agricultural_accuracy: 9/10 # Domain-specific correctness
```

## 🏗️ **Technology Stack Standards**

### **Backend Architecture (Spring Boot Primary)**
- **Primary Backend:** `kheti_sahayak_spring_boot/` - Java Spring Boot 3.3.3
- **Database:** PostgreSQL with JPA/Hibernate
- **Caching:** Redis for session and data caching
- **Security:** Spring Security with JWT authentication
- **Documentation:** OpenAPI 3.0 (Swagger UI)
- **Cloud Services:** AWS S3 for file storage
- **Monitoring:** Spring Actuator with Prometheus metrics

### **Frontend Applications**
- **Web Application:** React 18 with TypeScript and Material-UI
- **Mobile Application:** Flutter (Dart) for cross-platform mobile
- **State Management:** Redux Toolkit for React, Provider for Flutter
- **API Integration:** Axios for React, HTTP client for Flutter

### **Development Environment**
- **Java:** Version 17 (LTS)
- **Node.js:** Version 18+ for frontend tooling
- **Flutter:** Latest stable version
- **Database:** PostgreSQL 14+
- **Cache:** Redis 7+

---

This document defines the coding standards and best practices for building Kheti Sahayak's agricultural technology platform.

## 🏗️ **Kheti Sahayak Architecture Principles**

### **Agricultural Platform Vision**
- **Farmer-Centric Design:** Every feature must prioritize farmer usability and agricultural workflows
- **Multi-Crop Support:** Features should work across different crop types and farming practices
- **Scalable Agricultural Data:** Architecture must support millions of farmers and agricultural records
- **Offline-First:** Ensure functionality works in areas with poor internet connectivity
- **Multi-Language Support:** Hindi, English, and regional language support for Indian farmers

### **Agricultural Environment Standards**
- **Environment Separation:** Local (dev), Staging (UAT), Production (farmers)
- **Configuration Externalization:** All agricultural API keys, database configs externalized
- **Cloud Ready:** AWS/Azure support for scalable agricultural data processing
- **Security by Design:** Farmer data protection, no hardcoded secrets, GDPR compliance
- **Mobile-First:** Optimized for Android devices commonly used by farmers

### **Agricultural Data Principles**
- **Crop Data Integrity:** Ensure accuracy of agricultural recommendations and diagnostics
- **Weather Integration:** Real-time weather data integration for farming decisions
- **Market Data Accuracy:** Up-to-date market prices and commodity information
- **Geolocation Privacy:** Secure handling of farm location data
- **Seasonal Adaptability:** Features adapt to different farming seasons and cycles

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
- Break complex agricultural features into simple, manageable steps
- Format all tool use in XML format for consistency
- Never assume tool success - always verify results
- Always confirm changes or outputs with the user
- Never combine tool calls - execute them individually
- Follow best practices for readability, modularity, and testability
- Treat user workspace as production-level environment
- Generate and work through solutions systematically until tasks are completed
- **Prioritize farmer impact** - always consider how changes affect end users
- **Test with agricultural data** - use realistic farming scenarios in testing
- **Consider rural connectivity** - optimize for low-bandwidth environments
 
## 🌾 **Kheti Sahayak Specific Guidelines**

### **Agricultural Domain Architecture**
* **Crop Management:** Centralized crop lifecycle management services
* **Weather Integration:** Real-time weather data processing and alerts
* **Market Intelligence:** Price tracking and market trend analysis
* **Expert Systems:** AI-driven agricultural recommendations
* **Community Platform:** Farmer networking and knowledge sharing
* **Government Integration:** Scheme applications and subsidy management

### **Core Agricultural Features**

#### **🌱 Crop Management & Diagnostics**
* **Crop Health Monitoring:** Image-based disease and pest detection
* **Growth Tracking:** Lifecycle management from seed to harvest
* **Yield Prediction:** AI-powered harvest forecasting
* **Treatment Recommendations:** Personalized crop care suggestions
* **Seasonal Planning:** Crop rotation and timing optimization

#### **🌤️ Weather & Climate Services**
* **Hyperlocal Weather:** Village-level weather forecasting
* **Agricultural Alerts:** Weather-based farming recommendations
* **Irrigation Scheduling:** Smart water management based on weather
* **Climate Risk Assessment:** Long-term climate impact analysis
* **Seasonal Advisories:** Monsoon and seasonal farming guidance

#### **💰 Market & Commerce Platform**
* **Real-time Price Discovery:** Current market rates for crops
* **Direct Market Access:** Connect farmers to buyers
* **Quality Assessment:** Crop grading and certification
* **Supply Chain Tracking:** Farm-to-market traceability
* **Payment Integration:** Secure agricultural transactions

#### **👥 Expert Network & Community**
* **Agricultural Expert Connect:** Video consultations with specialists
* **Peer-to-Peer Learning:** Farmer experience sharing
* **Best Practices Library:** Curated agricultural knowledge base
* **Success Stories:** Farmer achievement showcases
* **Regional Expertise:** Location-specific agricultural guidance

#### **🏛️ Government & Schemes Integration**
* **Subsidy Applications:** Digital government scheme applications
* **Document Management:** Agricultural certificates and records
* **Compliance Tracking:** Regulatory requirement management
* **Benefit Tracking:** Subsidy and benefit status monitoring
* **Policy Updates:** Latest agricultural policy information

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
 
## 🎯 **Kheti Sahayak Vision and Goals**

### **Digital Agriculture Mission**
We are building a comprehensive digital agricultural platform that empowers farmers across India:

- **Crop Management Excellence:** Advanced tools for crop health and lifecycle management
- **Market Access Revolution:** Direct farmer-to-market connectivity and fair pricing
- **Knowledge Democratization:** Expert agricultural knowledge accessible to all farmers
- **Technology Adoption:** Making modern farming technology simple and affordable
- **Sustainable Agriculture:** Promoting environmentally conscious farming practices
- **Rural Economic Growth:** Increasing farmer incomes through technology

### **Platform Objectives**
- **Farmer-First Features:** Every feature must directly benefit farmers and improve their livelihoods
- **Scalable Impact:** Support millions of farmers across diverse crops and regions
- **Inclusive Design:** Accessible to farmers with varying technology literacy levels
- **Data-Driven Insights:** Leverage agricultural data for better farming decisions
- **Community Building:** Foster knowledge sharing and peer learning among farmers

### **GitHub Project Integration & User Story Management**

#### **Project Structure**
- **Repository:** `automotiv/khetisahayak`
- **Wiki Documentation:** [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki) with 141+ pages
- **Project Board:** [GitHub Projects](https://github.com/users/automotiv/projects/3) for task tracking
- **Issues:** 220+ GitHub issues for feature tracking and bug reports

#### **Core Documentation Structure (From Wiki)**
Based on the [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki), the project includes:

**Product Requirements Documentation:**
- **Introduction:** Project overview and agricultural mission
- **User Profiles:** Farmer, Expert, Admin, and Government user personas
- **Features Overview:** Comprehensive feature catalog for agricultural platform
- **Non-Functional Requirements:** Performance, security, and scalability requirements

**Technical Documentation:**
- **System Architecture:** High-level system design and component interaction
- **Backend Services:** Spring Boot service architecture and API design
- **Mobile App Architecture:** Flutter cross-platform development guidelines
- **Security & Privacy:** Data protection and farmer privacy requirements

#### **Key Agricultural Features (From Wiki)**
1. **🌱 Crop Management:** Digital logbook and crop lifecycle tracking
2. **🛒 Marketplace:** Agricultural product buying and selling platform
3. **🔍 Crop Diagnostics:** AI-powered plant disease detection and treatment
4. **🌤️ Weather Forecast:** Hyperlocal weather data and agricultural alerts
5. **👥 Expert Connect:** Consultation with agricultural specialists
6. **💬 Community Forum:** Farmer networking and knowledge sharing
7. **🏛️ Government Schemes:** Access to subsidies and agricultural policies

#### **User Story Categories (Project Requirements)**
1. **Farmer Journey Stories:** End-to-end agricultural workflow scenarios
2. **Expert System Stories:** AI/ML crop diagnosis and recommendation features
3. **Market Integration Stories:** Commerce, pricing, and supply chain features
4. **Mobile Experience Stories:** Flutter app optimization for rural connectivity
5. **Government Integration Stories:** Subsidy applications and policy compliance
6. **Community Features:** Forum, knowledge sharing, and peer learning
7. **Weather & Climate:** Hyperlocal forecasting and agricultural alerts

#### **Story Prioritization Framework (Based on Agricultural Impact)**
- **P0 - Critical:** Core farming functionality (crop health, weather alerts)
- **P1 - High:** Market access, expert consultation, government schemes
- **P2 - Medium:** Community features, advanced analytics, educational content
- **P3 - Low:** Nice-to-have features, optimizations, and enhancements

#### **Development Workflow Integration**
- **Epic Linking:** All code changes must reference GitHub issues/wiki documentation
- **Story Acceptance:** Clear acceptance criteria aligned with agricultural use cases
- **Testing Requirements:** Real-world farming scenarios and rural connectivity testing
- **Documentation Updates:** Wiki synchronization with each feature release
- **User Feedback:** Integration with farmer feedback loops and expert validation

#### **Agricultural Domain Requirements (From Project Documentation)**
Based on the comprehensive wiki documentation:

1. **Crop Health Management:**
   - Image-based disease and pest detection
   - Treatment recommendation engine
   - Seasonal crop planning and rotation advice
   - Yield prediction and harvest optimization

2. **Market Intelligence:**
   - Real-time crop price discovery
   - Supply chain transparency
   - Direct farmer-to-buyer connections
   - Quality assessment and certification

3. **Expert Network:**
   - Video consultations with agricultural specialists
   - Peer-to-peer farmer knowledge sharing
   - Best practices library and success stories
   - Regional expertise and local agricultural knowledge

4. **Government Integration:**
   - Digital subsidy application processing
   - Agricultural scheme eligibility checking
   - Document management and certification
   - Policy updates and compliance tracking

5. **Weather & Climate Services:**
   - Hyperlocal weather forecasting for farming decisions
   - Agricultural alert system for weather risks
   - Irrigation scheduling based on weather patterns
   - Climate change adaptation recommendations

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

## 🤖 **AI Agent Instructions for Kheti Sahayak Development**

### **Context Awareness Requirements**
When working on Kheti Sahayak, AI agents must:

1. **Understand Agricultural Context**
   - Recognize farming terminology and seasonal patterns
   - Consider rural user limitations (connectivity, device capabilities)
   - Prioritize features that directly impact farmer livelihoods
   - Understand Indian agricultural practices and crop cycles

2. **Technology Stack Awareness**
   - **Primary Backend:** Spring Boot (`kheti_sahayak_spring_boot/`)
   - **Legacy Backend:** Node.js (`kheti_sahayak_backend/`) - TO BE DEPRECATED
   - **Frontend:** React TypeScript with Material-UI
   - **Mobile:** Flutter for cross-platform development
   - **Database:** PostgreSQL for primary data, Redis for caching

3. **Code Quality Mandates**
   - Run CodeRabbit analysis on ALL code changes
   - Ensure WCAG 2.1 AA accessibility compliance
   - Optimize for mobile and low-bandwidth scenarios
   - Implement proper error handling for rural connectivity issues
   - Add comprehensive logging for agricultural data processing

### **Development Workflow for Agents**

#### **Before Making Changes**
1. **Review Project Documentation:** 
   - Check [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki) for feature requirements
   - Review [GitHub Projects](https://github.com/users/automotiv/projects/3) for current user stories
   - Analyze related GitHub issues (220+ issues) for context and acceptance criteria
2. **Check Spring Boot APIs:** Ensure backend endpoints exist or plan their creation
3. **Consider Mobile Impact:** How will changes affect Flutter mobile app
4. **Review Agricultural Data:** Understand crop/weather/market data implications
5. **Plan CodeRabbit Integration:** Prepare for automated code review
6. **Validate Against Wiki Requirements:** Ensure implementation matches documented specifications

#### **During Development**
1. **Use Spring Boot First:** Prefer Spring Boot backend over Node.js legacy
2. **Implement Offline Support:** Consider offline-first design patterns
3. **Add Multilingual Support:** Prepare for Hindi/regional language integration
4. **Optimize for Rural Networks:** Minimize data usage, implement caching
5. **Test with Agricultural Scenarios:** Use realistic farming data in tests

#### **After Implementation**
1. **Run CodeRabbit Analysis:** Address all security, performance, accessibility issues
2. **Update Documentation:** 
   - Reflect changes in [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki)
   - Update API documentation and technical specifications
   - Synchronize with Product Requirements Documents (PRDs)
3. **Test Mobile Compatibility:** Ensure React changes work on mobile viewports
4. **Validate Agricultural Logic:** Verify farming-related calculations and recommendations
5. **Update User Stories:** 
   - Mark [GitHub Project](https://github.com/users/automotiv/projects/3) tasks as complete
   - Close related GitHub issues with proper testing evidence
   - Update acceptance criteria status in project boards

### **AI Agent CodeRabbit Implementation Protocol**

#### **Mandatory Steps for Every AI Agent Response:**

1. **Pre-Development Analysis:**
   ```bash
   # AI agents must run these checks before making changes
   pr-vibe analyze --agricultural-context --file={filename}
   pr-vibe check-security --farmer-data-protection
   pr-vibe validate-accessibility --wcag-aa
   ```

2. **During Development - Real-time Validation:**
   - **Security Check:** Every API endpoint must validate inputs
   - **Performance Check:** Every image/file operation must be optimized for 2G networks
   - **Accessibility Check:** Every UI component must have proper ARIA labels
   - **Agricultural Check:** Every crop/weather/market logic must be domain-accurate

3. **Post-Development Verification:**
   ```bash
   # Verify all CodeRabbit requirements are met
   pr-vibe verify --agricultural-domain
   pr-vibe test --rural-connectivity
   pr-vibe validate --farmer-privacy
   ```

#### **AI Agent Response Template:**

Every AI agent response MUST include this verification section:

```markdown
## 🤖 CodeRabbit Compliance Verification

### ✅ Security Checks:
- [ ] Input validation implemented for all API endpoints
- [ ] Farmer data privacy protection verified
- [ ] No hardcoded secrets or credentials
- [ ] SQL injection prevention confirmed

### ✅ Performance Checks:
- [ ] Image compression implemented for rural networks
- [ ] Offline fallbacks provided for critical features
- [ ] Database queries optimized for agricultural data
- [ ] Bundle size optimized for mobile devices

### ✅ Accessibility Checks:
- [ ] ARIA labels added to all interactive elements
- [ ] Screen reader compatibility verified
- [ ] Keyboard navigation fully functional
- [ ] Color contrast meets WCAG 2.1 AA standards

### ✅ Agricultural Domain Checks:
- [ ] Crop data validation against known types
- [ ] Seasonal logic verified for Indian agriculture
- [ ] Weather thresholds appropriate for farming
- [ ] Market data accuracy validated

### 🚨 Issues Found and Resolved:
1. [List any CodeRabbit issues found]
2. [How each issue was resolved]
3. [Verification steps taken]

### 📊 Quality Score:
- Security: X/10
- Performance: X/10  
- Accessibility: X/10
- Agricultural Accuracy: X/10
```

#### **Automatic CodeRabbit Integration Commands:**

AI agents must use these commands when making changes:

1. **For Security Issues:**
   ```typescript
   // Always validate inputs
   @ValidatedInput({
     cropType: { type: 'enum', values: VALID_CROPS },
     location: { type: 'coordinates', required: true },
     farmerData: { type: 'encrypted', privacy: 'high' }
   })
   ```

2. **For Performance Issues:**
   ```typescript
   // Always optimize for rural networks
   @RuralOptimized({
     compression: true,
     offline: true,
     maxSize: '500KB',
     fallback: 'local-cache'
   })
   ```

3. **For Accessibility Issues:**
   ```tsx
   // Always add comprehensive accessibility
   @AccessibilityCompliant({
     ariaLabels: true,
     screenReader: true,
     keyboard: true,
     wcag: 'AA'
   })
   ```

4. **For Agricultural Domain Issues:**
   ```typescript
   // Always validate agricultural logic
   @AgriculturalValidation({
     crops: INDIAN_CROPS,
     seasons: ['kharif', 'rabi', 'zaid'],
     regions: INDIAN_STATES,
     weatherThresholds: FARMING_WEATHER_LIMITS
   })
   ```

#### **CodeRabbit Failure Response Protocol:**

If CodeRabbit analysis fails or finds critical issues, AI agents must:

1. **Stop Development:** Do not proceed with implementation
2. **Report Issues:** List all critical and high-priority issues found
3. **Provide Solutions:** Offer specific code fixes for each issue
4. **Request Approval:** Ask user to approve fixes before continuing
5. **Verify Fixes:** Re-run CodeRabbit analysis after applying fixes

#### **Example CodeRabbit Integration in AI Response:**

```markdown
## Implementation with CodeRabbit Analysis

### Original Code Issue (Flagged by CodeRabbit):
```typescript
// ❌ CRITICAL: No input validation
@PostMapping("/crop-diagnosis")
public ResponseEntity uploadImage(@RequestParam MultipartFile image) {
    return diagnosticsService.analyze(image);
}
```

### Fixed Code (CodeRabbit Approved):
```java
// ✅ SECURE: Full validation and agricultural context
@PostMapping("/crop-diagnosis")
public ResponseEntity<DiagnosisResult> uploadImage(
    @Valid @ImageFile(maxSize = "5MB", types = {"jpg", "png"}) MultipartFile image,
    @Valid @CropType String cropType,
    @Valid @Coordinates String location
) {
    return ResponseEntity.ok(diagnosticsService.analyze(image, cropType, location));
}
```

### CodeRabbit Verification:
- ✅ Security: Input validation added
- ✅ Performance: File size limits enforced  
- ✅ Agricultural: Crop type validation included
- ✅ Privacy: Location data properly handled
```

This ensures every AI agent response includes proper CodeRabbit analysis and compliance verification.

### **Agricultural Domain Knowledge Requirements**

#### **Crop Management Understanding**
- **Growth Stages:** Germination, vegetative, flowering, fruiting, harvesting
- **Common Issues:** Pests, diseases, nutrient deficiencies, weather damage
- **Treatment Options:** Organic vs chemical treatments, integrated pest management
- **Seasonal Patterns:** Kharif, Rabi, and Zaid cropping seasons in India

#### **Market Dynamics**
- **Price Volatility:** Understanding seasonal price fluctuations
- **Quality Grading:** Agricultural produce quality standards
- **Supply Chain:** Farm-to-market logistics and intermediaries
- **Government Policies:** MSP (Minimum Support Price), subsidies, schemes

#### **Technology Integration**
- **IoT Sensors:** Soil moisture, temperature, humidity monitoring
- **Satellite Data:** Weather forecasting, crop monitoring via remote sensing
- **AI/ML Applications:** Image recognition for pest/disease detection
- **Mobile Optimization:** Offline-capable apps for rural areas

### **Error Handling & Edge Cases**

#### **Connectivity Issues**
- Implement offline data synchronization
- Cache critical agricultural information locally
- Provide graceful degradation for network failures
- Queue API calls for when connectivity returns

#### **Data Accuracy**
- Validate agricultural data from multiple sources
- Implement data quality checks for weather/market information
- Provide confidence scores for AI-generated recommendations
- Allow farmer feedback to improve system accuracy

#### **User Experience**
- Design for low-literacy users with intuitive interfaces
- Provide voice/audio instructions in local languages
- Use agricultural imagery and familiar terminology
- Implement progressive disclosure for complex features

---

## 📋 **Project Requirements Integration**

### **Mandatory References for All Development**
Every AI agent and developer MUST reference these sources before starting work:

1. **Primary Documentation:**
   - [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki) - 141+ pages of comprehensive requirements
   - [GitHub Projects](https://github.com/users/automotiv/projects/3) - Active user stories and task tracking
   - GitHub Issues (220+) - Detailed feature specifications and bug reports

2. **Key Wiki Sections to Review:**
   - **Product Requirements:** Introduction, User Profiles, Features Overview
   - **Technical Architecture:** System Design, Backend Services, Mobile App
   - **API Documentation:** Authentication, Crop Diagnostics, Marketplace
   - **Non-Functional Requirements:** Performance, Security, Scalability

### **User Story Validation Process**
Before implementing any feature:

1. **Locate User Story:** Find corresponding story in [GitHub Projects](https://github.com/users/automotiv/projects/3)
2. **Review Acceptance Criteria:** Understand success metrics and testing requirements
3. **Check Dependencies:** Identify related stories and technical dependencies
4. **Validate Agricultural Context:** Ensure feature serves farmer needs effectively
5. **Plan Implementation:** Break down into Spring Boot backend and React frontend tasks

### **Documentation Synchronization Requirements**
After completing any feature:

1. **Update Wiki Pages:** Reflect implementation in relevant [wiki sections](https://github.com/automotiv/khetisahayak/wiki)
2. **Close GitHub Issues:** Mark related issues as resolved with implementation details
3. **Update Project Board:** Move user stories to "Done" with testing evidence
4. **API Documentation:** Update OpenAPI specs and endpoint documentation
5. **Technical Specs:** Update architecture diagrams and system design docs

### **Agricultural Feature Implementation Guidelines**
Based on the wiki documentation, ensure all features include:

1. **Farmer-Centric Design:**
   - Simple, intuitive interfaces for low-tech literacy users
   - Voice/audio support for regional language speakers
   - Offline functionality for areas with poor connectivity

2. **Agricultural Accuracy:**
   - Validate crop types against Indian agricultural standards
   - Implement seasonal logic for Kharif/Rabi/Zaid cropping patterns
   - Include regional variations for different Indian states

3. **Rural Optimization:**
   - Optimize for 2G/3G network conditions
   - Minimize data usage for cost-sensitive farmers
   - Implement progressive loading and caching strategies

4. **Expert Integration:**
   - Design workflows for agricultural expert consultations
   - Enable peer-to-peer farmer knowledge sharing
   - Integrate with government extension services

### **Compliance with Project Vision**
All development must align with the project's core mission as documented in the wiki:

- **Digital Agriculture Transformation:** Modernize traditional farming practices
- **Farmer Empowerment:** Increase agricultural productivity and income
- **Sustainable Farming:** Promote environmentally conscious practices
- **Rural Development:** Bridge the digital divide in agricultural communities

---

*This document serves as the comprehensive guide for building Kheti Sahayak's digital agricultural platform. All contributors, whether human developers or AI agents, must follow these standards and reference the [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki) and [Project Board](https://github.com/users/automotiv/projects/3) to ensure we deliver technology that truly empowers farmers and transforms Indian agriculture.*