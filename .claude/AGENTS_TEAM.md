# 🌾 Kheti Sahayak AI Development Team

Welcome to your comprehensive AI development team! This document describes the 27 specialized AI agents created for the Kheti Sahayak project.

## 📊 Team Structure

### **C-Level Executives (3 agents)**

1. **@cto** - Chief Technology Officer
   - Strategic technology leadership and architecture oversight
   - Model: Claude Opus 4.5
   - Use for: Major technical decisions, architecture reviews, technology strategy

2. **@cpo** - Chief Product Officer
   - Product strategy, user experience, and feature roadmap
   - Model: Claude Opus 4.5
   - Use for: Product decisions, feature prioritization, UX strategy

3. **@head-of-ai-ml** - Head of AI/ML
   - Machine learning strategy, model development, and AI infrastructure
   - Model: Claude Opus 4.5
   - Use for: ML strategy, model architecture decisions, AI roadmap

### **Senior Leadership (5 agents)**

4. **@solutions-architect** - Solutions Architect
   - System design, integration patterns, and technical architecture
   - Model: Claude Opus 4.5
   - Use for: System architecture, integration design, technical patterns

5. **@frontend-tech-lead** - Frontend Tech Lead
   - Web frontend architecture, React/Vue expertise
   - Model: Claude Sonnet 4.5
   - Use for: Frontend architecture, React/Vue decisions, build configuration

6. **@backend-tech-lead** - Backend Tech Lead
   - Backend architecture, API design, database strategy
   - Model: Claude Sonnet 4.5
   - Use for: Backend architecture, API design, database decisions

7. **@mobile-tech-lead** - Mobile Tech Lead
   - Flutter architecture, mobile app performance, native integrations
   - Model: Claude Sonnet 4.5
   - Use for: Mobile architecture, Flutter decisions, platform integrations

8. **@devops-lead** - DevOps Lead
   - CI/CD, infrastructure automation, monitoring
   - Model: Claude Sonnet 4.5
   - Use for: DevOps strategy, infrastructure decisions, deployment pipelines

### **Senior Developers (6 agents)**

9. **@senior-flutter-developer** - Senior Flutter Developer
   - Mobile app features, state management, native integrations
   - Model: Claude Sonnet 4.5

10. **@senior-backend-python-developer** - Senior Backend Developer (Python)
    - FastAPI services, ML integration, async processing
    - Model: Claude Sonnet 4.5

11. **@senior-backend-java-developer** - Senior Backend Developer (Java)
    - Spring Boot services, payment integration, enterprise features
    - Model: Claude Sonnet 4.5

12. **@senior-ml-engineer** - Senior ML Engineer
    - Model training, optimization, deployment, MLOps
    - Model: Claude Sonnet 4.5

13. **@senior-frontend-developer** - Senior Frontend Developer
    - React/Vue components, responsive UI, state management
    - Model: Claude Sonnet 4.5

14. **@senior-devops-engineer** - Senior DevOps Engineer
    - Kubernetes, cloud infrastructure, CI/CD automation
    - Model: Claude Sonnet 4.5

### **Mid-Level Developers (6 agents)**

15. **@fullstack-developer** - Full Stack Developer
    - End-to-end feature development across frontend and backend
    - Model: Claude Sonnet 4.5

16. **@mobile-developer** - Mobile Developer
    - Flutter app features, UI implementation, API integration
    - Model: Claude Sonnet 4.5

17. **@backend-api-developer** - Backend API Developer
    - RESTful APIs, database operations, business logic
    - Model: Claude Sonnet 4.5

18. **@ml-model-developer** - ML Model Developer
    - Model training, data preprocessing, experiment tracking
    - Model: Claude Sonnet 4.5

19. **@qa-engineer** - QA Engineer
    - Test automation, quality assurance, bug tracking
    - Model: Claude Sonnet 4.5

20. **@security-engineer** - Security Engineer
    - Application security, vulnerability assessment, secure coding
    - Model: Claude Sonnet 4.5

### **Junior Developers (3 agents)**

21. **@junior-frontend-developer** - Junior Frontend Developer
    - UI components, styling, basic interactivity
    - Model: Claude Haiku 4.5

22. **@junior-backend-developer** - Junior Backend Developer
    - API endpoints, database queries, basic business logic
    - Model: Claude Haiku 4.5

23. **@junior-mobile-developer** - Junior Mobile Developer
    - Flutter widgets, basic features, UI implementation
    - Model: Claude Haiku 4.5

### **Specialists (4 agents)**

24. **@database-specialist** - Database Specialist
    - Database design, optimization, migrations, data integrity
    - Model: Claude Sonnet 4.5

25. **@ui-ux-designer** - UI/UX Designer
    - User interface design, user experience, design systems
    - Model: Claude Sonnet 4.5

26. **@technical-writer** - Technical Writer
    - Documentation, API docs, user guides, knowledge base
    - Model: Claude Sonnet 4.5

27. **@api-integration-specialist** - API Integration Specialist
    - Third-party integrations, webhooks, external services
    - Model: Claude Sonnet 4.5

## 💡 How to Use Your AI Team

### Calling Individual Agents

In your OpenCode session, you can call any agent using the `@` mention:

```
@cto Review the current architecture and suggest improvements for scalability
```

```
@senior-flutter-developer Implement the disease detection camera screen
```

```
@qa-engineer Create a comprehensive test plan for the payment flow
```

### Using Multiple Agents in Parallel

With oh-my-opencode's background agent feature, you can run multiple agents simultaneously:

```
ultrawork: @senior-backend-python-developer build the disease detection API
while @senior-flutter-developer implements the mobile UI in parallel
```

### Team Collaboration Patterns

**Feature Development Pattern:**
```
1. @cpo - Define feature requirements
2. @solutions-architect - Design system architecture
3. @senior-backend-python-developer - Build API
4. @senior-flutter-developer - Build mobile UI
5. @qa-engineer - Test the feature
```

**Bug Fix Pattern:**
```
1. @qa-engineer - Reproduce and document the bug
2. @senior-* - Fix the issue
3. @security-engineer - Review if security-related
4. @qa-engineer - Verify the fix
```

**New Feature Launch Pattern:**
```
1. @cpo - Define requirements and user stories
2. @ui-ux-designer - Create designs and prototypes
3. @cto + @solutions-architect - Review technical approach
4. Multiple developers in parallel - Implement
5. @qa-engineer - Comprehensive testing
6. @technical-writer - Documentation
7. @devops-lead - Deployment strategy
```

## 🎯 Best Practices

### 1. **Choose the Right Agent for the Task**
   - Use senior agents for complex, critical decisions
   - Use mid-level agents for standard feature development
   - Use junior agents for simple, well-defined tasks
   - Use specialists for their specific domains

### 2. **Leverage Parallel Execution**
   ```
   Use the "ultrawork" keyword to enable parallel agent execution:

   ultrawork: Build the marketplace feature with @backend-tech-lead handling
   the API architecture, @frontend-tech-lead building the web UI, and
   @mobile-tech-lead implementing the mobile interface simultaneously
   ```

### 3. **Start with Leadership for Complex Tasks**
   ```
   For major features, always start with leadership:

   @cto What's the best architecture for implementing real-time
   expert consultation with video/audio calls?
   ```

### 4. **Use Specialists for Their Expertise**
   ```
   @database-specialist Optimize the crop disease history query that's
   taking 5 seconds to execute

   @security-engineer Review our payment flow for PCI DSS compliance

   @ui-ux-designer Create a user-friendly interface for illiterate farmers
   ```

### 5. **Code Reviews Across Levels**
   ```
   After implementation:

   @senior-backend-python-developer Review this code written by
   @junior-backend-developer and provide mentorship feedback
   ```

## 🚀 Example Workflows

### Implementing Disease Detection Feature

```
Day 1: Planning
@cpo Define the disease detection feature requirements
@head-of-ai-ml What ML model architecture should we use?
@solutions-architect Design the end-to-end system architecture

Day 2-3: Development (Parallel)
@senior-ml-engineer Train and optimize the disease detection model
@senior-backend-python-developer Build the image upload and inference API
@senior-flutter-developer Implement camera capture and result display UI

Day 4: Integration & Testing
@fullstack-developer Integrate frontend and backend
@qa-engineer Test the complete flow across devices
@security-engineer Review image upload security

Day 5: Documentation & Deployment
@technical-writer Create user guide and API documentation
@devops-lead Deploy to production with monitoring
```

### Optimizing Performance

```
@cto We're experiencing slow load times. Can you coordinate a
performance optimization effort?

Then in parallel:
@frontend-tech-lead Optimize bundle size and loading performance
@backend-tech-lead Review and optimize API response times
@database-specialist Optimize slow database queries
@senior-devops-engineer Review infrastructure and add caching layers
```

## 📈 Team Hierarchy

```
CTO
├── Solutions Architect
├── Head of AI/ML
│   ├── Senior ML Engineer
│   └── ML Model Developer
├── Frontend Tech Lead
│   ├── Senior Frontend Developer
│   ├── Fullstack Developer
│   └── Junior Frontend Developer
├── Backend Tech Lead
│   ├── Senior Backend Developer (Python)
│   ├── Senior Backend Developer (Java)
│   ├── Backend API Developer
│   └── Junior Backend Developer
├── Mobile Tech Lead
│   ├── Senior Flutter Developer
│   ├── Mobile Developer
│   └── Junior Mobile Developer
├── DevOps Lead
│   ├── Senior DevOps Engineer
│   └── API Integration Specialist
└── Specialists
    ├── Database Specialist
    ├── Security Engineer
    ├── QA Engineer
    ├── UI/UX Designer
    └── Technical Writer

CPO (parallel to CTO)
└── UI/UX Designer
```

## 🎨 Agent Colors Reference

Each agent has a unique color for easy identification:
- **Red tones**: Leadership and strategic roles
- **Blue tones**: Frontend and UI
- **Green tones**: Backend and APIs
- **Purple tones**: ML and AI
- **Orange tones**: DevOps and Infrastructure
- **Light tones**: Junior roles

## 💪 Getting Started

1. **Open your project in OpenCode:**
   ```bash
   cd /Users/ponali.prakash/Documents/practice/khetisahayak
   opencode
   ```

2. **Start with a leadership agent for planning:**
   ```
   @cto Review our current codebase and suggest the top 5
   improvements we should prioritize
   ```

3. **Use the magic keyword for complex tasks:**
   ```
   ultrawork: Implement the complete marketplace feature with
   product listings, shopping cart, and payment integration
   ```

4. **Call specialists as needed:**
   ```
   @security-engineer Audit our authentication system
   @database-specialist Optimize our farmer data queries
   ```

## 🎉 Your Team is Ready!

You now have a complete AI development team of 27 specialized agents ready to build Kheti Sahayak. Each agent brings unique expertise and works with appropriate Claude models (Opus 4.5 for leadership, Sonnet 4.5 for most development, Haiku 4.5 for junior roles).

Start building amazing features for Indian farmers! 🌾✨
