# 🌾 Kheti Sahayak - Contributor Guide

Welcome to the Kheti Sahayak contributor community! This guide will help you get started with contributing to our agricultural technology platform.

## 📋 Table of Contents

- [Quick Links](#quick-links)
- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contribution Workflow](#contribution-workflow)
- [Coding Standards](#coding-standards)
- [Community Guidelines](#community-guidelines)
- [Getting Help](#getting-help)

## 🔗 Quick Links

- **📚 Documentation:** [GitHub Wiki](https://github.com/automotiv/khetisahayak/wiki)
- **🎯 Project Board:** [Current Priorities](https://github.com/users/automotiv/projects/3)
- **📋 PRD Index:** [Product Requirements](https://github.com/automotiv/khetisahayak/wiki/PRD_Index)
- **💬 Discussions:** [GitHub Discussions](https://github.com/automotiv/khetisahayak/discussions)
- **📖 Contributing Guide:** [CONTRIBUTING.md](CONTRIBUTING.md)

## 🤝 Ways to Contribute

We welcome all types of contributions:

### 🔧 Code Contributions

#### Frontend (Flutter)
- **Good For:** Mobile developers, UI/UX enthusiasts
- **Tech Stack:** Flutter 3.10+, Dart, Provider/Riverpod
- **Areas:**
  - UI/UX improvements
  - Offline functionality
  - Performance optimization
  - Accessibility features

#### Backend (Node.js / Spring Boot)
- **Good For:** Backend developers, API designers
- **Tech Stack:** Node.js 18+, Express.js, Spring Boot
- **Areas:**
  - REST API development
  - Database optimization
  - Third-party integrations
  - Microservices architecture

#### AI/ML Models
- **Good For:** Data scientists, ML engineers
- **Tech Stack:** TensorFlow, PyTorch, Python
- **Areas:**
  - Crop disease detection models
  - Model accuracy improvements
  - Edge deployment optimization
  - Dataset curation

### 📚 Documentation

- **PRD Writing:** Help document new features
- **API Documentation:** Improve Swagger/OpenAPI specs
- **Tutorials:** Create user guides and developer tutorials
- **Translations:** Translate docs to regional Indian languages

### 🎨 Design

- **UI/UX Design:** Create mockups and user flows
- **Iconography:** Design icons for low-literacy users
- **Branding:** Help with visual identity
- **Accessibility:** Ensure designs work for all users

### 🧪 Testing & QA

- **Manual Testing:** Test on real devices
- **Automated Testing:** Write unit/integration tests
- **Field Testing:** Test with farmers in rural areas
- **Bug Reports:** Report and triage issues

### 🌍 Community & Outreach

- **Community Management:** Help moderate forums
- **User Research:** Conduct farmer interviews
- **Content Creation:** Write blog posts, create videos
- **Translation:** Translate app to regional languages

## 🚀 Getting Started

### 1. Find an Issue

Browse our issues to find something to work on:

- **🟢 Good First Issues:** [Perfect for beginners](https://github.com/automotiv/khetisahayak/labels/good%20first%20issue)
- **🆘 Help Wanted:** [Community help needed](https://github.com/automotiv/khetisahayak/labels/help%20wanted)
- **📋 PRD Proposals:** [Features needing documentation](https://github.com/automotiv/khetisahayak/labels/prd)
- **🐛 Bugs:** [Issues to fix](https://github.com/automotiv/khetisahayak/labels/bug)

### 2. Understand the Feature

Before starting work:

1. **Read the PRD:** Check if there's a PRD in the [Wiki](https://github.com/automotiv/khetisahayak/wiki)
2. **Check Dependencies:** Look for related issues
3. **Review Acceptance Criteria:** Understand what "done" means
4. **Ask Questions:** Comment on the issue or start a discussion

### 3. Claim the Issue

Comment on the issue saying you'd like to work on it:

```
Hi! I'd like to work on this issue.

My approach:
- Step 1
- Step 2
- Step 3

Estimated completion: X days

Please assign this to me if that works!
```

## 💻 Development Setup

### Prerequisites

- **Node.js:** v18.0+ ([Download](https://nodejs.org/))
- **Flutter:** v3.10+ ([Install Guide](https://flutter.dev/docs/get-started/install))
- **PostgreSQL:** v14+ ([Download](https://postgresql.org/download/))
- **Redis:** v6.2+ ([Install Guide](https://redis.io/download))
- **Docker:** Latest (optional) ([Get Docker](https://docs.docker.com/get-docker/))
- **Git:** Latest ([Download](https://git-scm.com/))

### Quick Setup

```bash
# 1. Fork and clone the repository
git clone https://github.com/YOUR-USERNAME/khetisahayak.git
cd khetisahayak

# 2. Add upstream remote
git remote add upstream https://github.com/automotiv/khetisahayak.git

# 3. Run automated setup
chmod +x setup.sh
./setup.sh

# 4. Start development environment
npm run dev:all
```

### Manual Setup

#### Backend Setup

```bash
cd kheti_sahayak_backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start databases (Docker)
docker-compose up -d postgres redis

# Initialize database
npm run db:setup

# Start development server
npm run dev
```

Backend runs at: http://localhost:3000
API Docs: http://localhost:3000/api-docs

#### Frontend Setup

```bash
cd kheti_sahayak_app

# Install dependencies
flutter pub get

# Configure environment
cp lib/.env.example lib/.env
# Update API_BASE_URL in lib/.env

# Run the app
flutter run
```

#### ML Service Setup (Optional)

```bash
cd ml

# Build Docker image
docker build -t kheti-ml-inference -f Dockerfile.inference .

# Run ML service
docker run -p 8000:8000 kheti-ml-inference
```

## 🔄 Contribution Workflow

### 1. Create a Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create a feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### 2. Make Changes

- Write clean, documented code
- Follow our [coding standards](#coding-standards)
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Backend tests
cd kheti_sahayak_backend
npm test
npm run test:coverage

# Frontend tests
cd kheti_sahayak_app
flutter test
flutter test --coverage

# Linting
npm run lint
flutter analyze
```

### 4. Commit Your Changes

Use [Conventional Commits](https://conventionalcommits.org/):

```bash
# Good commit messages
git commit -m "feat(diagnostics): add offline image caching"
git commit -m "fix(marketplace): resolve payment gateway timeout"
git commit -m "docs(prd): update marketplace requirements"
git commit -m "test(api): add integration tests for user auth"
```

**Commit Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code formatting (no logic change)
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks
- `perf:` Performance improvements

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create Pull Request on GitHub
# Use our PR template and fill it completely
```

### PR Checklist

- [ ] Tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Changelog entry added (if applicable)
- [ ] Screenshots included (for UI changes)
- [ ] Linked to related issue(s)
- [ ] Self-reviewed the code
- [ ] Requested review from maintainers

## 📏 Coding Standards

### General Principles

- **Clarity over Cleverness:** Write readable code
- **DRY (Don't Repeat Yourself):** Avoid code duplication
- **SOLID Principles:** Follow object-oriented best practices
- **Meaningful Names:** Use descriptive variable/function names
- **Comments:** Explain the "why", not the "what"

### Backend (Node.js)

```javascript
// Good example
const getUserAuthenticationToken = async (userId) => {
  try {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    return generateToken(user);
  } catch (error) {
    logger.error('Error generating auth token:', error);
    throw error;
  }
};

// Use async/await instead of callbacks
// Proper error handling
// Meaningful variable names
```

### Frontend (Flutter/Dart)

```dart
// Good example
class CropDiagnosticsService {
  Future<DiagnosisResult> uploadImageForDiagnosis(File image) async {
    try {
      final response = await _apiClient.uploadImage(image);
      return DiagnosisResult.fromJson(response.data);
    } catch (e) {
      _logger.error('Error uploading image: $e');
      rethrow;
    }
  }
}

// Clear class and method names
// Proper error handling
// Async/await for asynchronous operations
```

### AI/ML (Python)

```python
# Good example
def preprocess_crop_image(image_path: str, target_size: Tuple[int, int]) -> np.ndarray:
    """
    Preprocess crop image for model inference.

    Args:
        image_path: Path to the crop image
        target_size: Target dimensions (width, height)

    Returns:
        Preprocessed image as numpy array
    """
    image = cv2.imread(image_path)
    image = cv2.resize(image, target_size)
    image = image / 255.0  # Normalize
    return np.expand_dims(image, axis=0)

# Type hints
# Docstrings
# Clear function purpose
```

### Testing Standards

```javascript
// Backend test example
describe('User Authentication', () => {
  it('should generate valid JWT token', async () => {
    const user = { id: 1, phone: '+919876543210' };
    const token = await authService.generateToken(user);

    expect(token).toBeDefined();
    expect(typeof token).toBe('string');

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    expect(decoded.userId).toBe(user.id);
  });
});
```

```dart
// Flutter test example
void main() {
  group('CropDiagnosticsService', () {
    test('should parse diagnosis result correctly', () {
      final json = {
        'disease': 'Powdery Mildew',
        'confidence': 0.95,
        'treatment': 'Apply fungicide'
      };

      final result = DiagnosisResult.fromJson(json);

      expect(result.disease, equals('Powdery Mildew'));
      expect(result.confidence, equals(0.95));
    });
  });
}
```

## 👥 Community Guidelines

### Code of Conduct

We follow a strict [Code of Conduct](CODE_OF_CONDUCT.md). Key points:

- **Be Respectful:** Treat everyone with respect
- **Be Inclusive:** Welcome diverse perspectives
- **Be Collaborative:** Help others succeed
- **Be Professional:** Focus on technical merits
- **Zero Tolerance:** No harassment, discrimination, or abuse

### Communication Channels

- **💬 GitHub Discussions:** General questions, ideas, and community chat
- **🐛 GitHub Issues:** Bug reports and feature requests
- **📧 Email:** support@khetisahayak.com for sensitive matters
- **📱 Community Forum:** (Coming soon) For farmers and end-users

### Response Times

- **Issues:** We aim to respond within 48 hours
- **PRs:** Initial review within 72 hours
- **Discussions:** Community-driven, responses vary

## 🆘 Getting Help

### Stuck? Here's How to Get Unblocked

1. **Search Existing Issues:** Someone may have faced the same problem
2. **Check Documentation:** Review the [Wiki](https://github.com/automotiv/khetisahayak/wiki)
3. **Ask in Discussions:** Start a [discussion](https://github.com/automotiv/khetisahayak/discussions)
4. **Comment on Issue:** Ask questions on the issue you're working on
5. **Contact Maintainers:** Mention @automotiv in your comment

### Debugging Resources

- **Backend Logs:** `tail -f kheti_sahayak_backend/logs/app.log`
- **Flutter DevTools:** `flutter pub global run devtools`
- **API Testing:** Use Postman or http://localhost:3000/api-docs
- **Database:** Adminer at http://localhost:8080

## 🏆 Recognition

Contributors are recognized in:

- **📝 CONTRIBUTORS.md:** All contributors listed
- **🎉 Release Notes:** Significant contributions highlighted
- **🐦 Social Media:** Shoutouts on Twitter/LinkedIn
- **🏅 GitHub Badges:** Contributor badges on your profile

### Contributor Levels

- **🌱 New Contributor:** First PR merged
- **🌿 Active Contributor:** 5+ PRs merged
- **🌳 Core Contributor:** 20+ PRs merged
- **🌲 Maintainer:** Regular reviewer and guide

## 📊 Project Stats

![GitHub contributors](https://img.shields.io/github/contributors/automotiv/khetisahayak)
![GitHub issues](https://img.shields.io/github/issues/automotiv/khetisahayak)
![GitHub pull requests](https://img.shields.io/github/issues-pr/automotiv/khetisahayak)
![GitHub stars](https://img.shields.io/github/stars/automotiv/khetisahayak)

## 🙏 Thank You!

Every contribution, no matter how small, makes a difference in empowering farmers across India. Thank you for being part of this mission!

---

**Questions?** Start a [discussion](https://github.com/automotiv/khetisahayak/discussions) or email us at contribute@khetisahayak.com

**Ready to contribute?** Check out [good first issues](https://github.com/automotiv/khetisahayak/labels/good%20first%20issue)!
