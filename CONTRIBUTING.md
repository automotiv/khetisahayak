# 🤝 Contributing to Kheti Sahayak

We love your input! We want to make contributing to Kheti Sahayak as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## 🚀 Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

### 📋 Prerequisites

Before contributing, ensure you have:

- ✅ Read our [Code of Conduct](CODE_OF_CONDUCT.md)
- ✅ Set up the development environment (see [README.md](README.md))
- ✅ Familiarized yourself with the project structure
- ✅ Joined our [Discord community](https://discord.gg/khetisahayak) (optional)

## 🔄 Pull Request Process

### 1. Fork & Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/your-username/khetisahayak.git
cd khetisahayak

# Add upstream remote
git remote add upstream https://github.com/original-owner/khetisahayak.git
```

### 2. Create a Branch

```bash
# Create and switch to a new branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description

# Or for documentation
git checkout -b docs/documentation-update
```

### 3. Make Changes

- Write clear, concise code
- Follow our coding standards
- Add tests for new functionality
- Update documentation as needed

### 4. Test Your Changes

```bash
# Backend tests
cd kheti_sahayak_spring_boot
npm test
npm run test:coverage

# Frontend tests
cd kheti_sahayak_app
flutter test
flutter test --coverage

# Run integration tests
npm run test:integration
```

### 5. Commit Your Changes

We use [Conventional Commits](https://conventionalcommits.org/):

```bash
# Examples of good commit messages
git commit -m "feat: add crop disease detection API"
git commit -m "fix: resolve authentication token expiry issue"
git commit -m "docs: update API documentation for marketplace"
git commit -m "test: add unit tests for user registration"
```

### 6. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create a Pull Request on GitHub
# Fill out the PR template completely
```

## 📝 Coding Standards

### 🖥️ Backend (Spring Boot)

```javascript
// Use meaningful variable names
const userAuthenticationToken = generateToken(user);

// Use async/await instead of callbacks
const getUserData = async (userId) => {
  try {
    const user = await User.findById(userId);
    return user;
  } catch (error) {
    logger.error('Error fetching user:', error);
    throw error;
  }
};

// Use proper error handling
app.use((error, req, res, next) => {
  logger.error(error.stack);
  res.status(500).json({ 
    success: false, 
    message: 'Internal server error' 
  });
});
```

### 📱 Frontend (Flutter/Dart)

```dart
// Use descriptive class and method names
class CropDiagnosticsService {
  Future<DiagnosisResult> uploadImageForDiagnosis(File image) async {
    try {
      final response = await _apiClient.uploadImage(image);
      return DiagnosisResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }
}

// Use proper state management
class DiagnosticsProvider extends ChangeNotifier {
  List<Diagnosis> _diagnoses = [];
  bool _isLoading = false;

  List<Diagnosis> get diagnoses => _diagnoses;
  bool get isLoading => _isLoading;

  Future<void> loadDiagnoses() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _diagnoses = await _diagnosticsService.getDiagnoses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## 🧪 Testing Guidelines

### Unit Tests

- Test individual functions and classes
- Mock external dependencies
- Aim for >80% code coverage

```javascript
// Backend unit test example
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
// Frontend unit test example
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
      expect(result.treatment, equals('Apply fungicide'));
    });
  });
}
```

### Integration Tests

- Test API endpoints end-to-end
- Test complete user workflows
- Use test databases

## 📋 Issue Guidelines

### 🐛 Bug Reports

Use our bug report template and include:

- **Clear description** of the issue
- **Steps to reproduce** the bug
- **Expected vs actual behavior**
- **Screenshots or error logs** if applicable
- **Environment details** (OS, browser, app version)

### 💡 Feature Requests

Use our feature request template and include:

- **Problem statement** - what problem does this solve?
- **Proposed solution** - how would you like it to work?
- **Alternative solutions** - what other approaches did you consider?
- **Use cases** - who would benefit from this feature?

## 🎯 Contribution Areas

We welcome contributions in these areas:

### 🔧 Code Contributions

- **Backend API development**
- **Mobile app features**
- **Web portal development**
- **Database optimizations**
- **Performance improvements**

### 📚 Documentation

- **API documentation**
- **User guides**
- **Developer tutorials**
- **Code examples**
- **Translation** (Hindi, regional languages)

### 🧪 Testing

- **Unit test coverage**
- **Integration tests**
- **Performance testing**
- **User acceptance testing**
- **Security testing**

### 🎨 Design & UX

- **UI/UX improvements**
- **Accessibility enhancements**
- **Mobile responsiveness**
- **Design system components**

## 🏆 Recognition

Contributors will be recognized in:

- 📝 **CONTRIBUTORS.md** file
- 🎉 **Release notes** for significant contributions
- 🐦 **Social media** shoutouts
- 🏅 **Contributor badges** on GitHub

## 📞 Getting Help

If you need help or have questions:

- 💬 **Discord**: Join our [developer community](https://discord.gg/khetisahayak)
- 📧 **Email**: contribute@khetisahayak.com
- 🎫 **GitHub Issues**: Ask questions using the question template
- 📖 **Documentation**: Check our [docs](docs/README.md)

## 📜 Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md). We are committed to providing a welcoming and inspiring community for all.

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License that covers the project.

---

**Thank you for contributing to Kheti Sahayak! 🌾**

*Together, we're building technology that empowers farmers and transforms agriculture in India.*
