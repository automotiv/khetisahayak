# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email security concerns to: security@khetisahayak.com (or create a private security advisory)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Resolution Timeline**: Depends on severity
  - Critical: 24-48 hours
  - High: 7 days
  - Medium: 30 days
  - Low: 90 days

### Security Measures in Place

- Dependabot for dependency updates
- CodeQL for static analysis
- Secret scanning enabled
- npm audit in CI pipeline
- Input validation and sanitization
- JWT-based authentication
- Rate limiting on API endpoints
- HTTPS enforced in production

## Security Best Practices for Contributors

1. Never commit secrets, API keys, or credentials
2. Use environment variables for sensitive data
3. Validate and sanitize all user inputs
4. Keep dependencies updated
5. Follow the principle of least privilege
6. Use parameterized queries (no raw SQL with user input)
