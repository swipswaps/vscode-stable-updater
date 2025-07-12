# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Security Standards Compliance

This project adheres to strict security standards and Augment Settings compliance:

### ✅ **Input Validation**
- All user inputs are validated before processing
- Edition parameters restricted to 'stable' or 'insiders'
- File paths validated for safety
- URL construction uses safe methods

### ✅ **Safe File Operations**
- Ownership verification before file deletion
- Safe path validation for temporary directories
- No operations outside of safe paths (`/tmp/*`, `/var/tmp/*`, `~/.cache/*`)
- Proper permissions checking

### ✅ **Process Management**
- Graceful process termination (SIGTERM before SIGKILL)
- Process existence verification before operations
- Timeout-based process management
- No privilege escalation beyond necessary sudo for package installation

### ✅ **Resource Management**
- Comprehensive cleanup of all temporary resources
- Signal handler registration for all exit scenarios
- Background process tracking and termination
- Lock file protection against concurrent executions

### ✅ **Network Security**
- HTTPS-only downloads from official Microsoft servers
- User-Agent identification for transparency
- Connection timeouts to prevent hanging
- Retry logic with exponential backoff

### ✅ **Credential Security**
- No hardcoded credentials or secrets
- No API keys or tokens in source code
- Environment variable support for configuration
- Secure temporary file creation with mktemp

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

### 📧 **Contact Information**
- **Email**: [Create an issue](https://github.com/swipswaps/vscode-stable-updater/issues) with "SECURITY" label
- **Response Time**: We aim to respond within 48 hours
- **Disclosure**: We follow responsible disclosure practices

### 🔍 **What to Include**
1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Potential impact** assessment
4. **Suggested fix** (if available)
5. **Your contact information** for follow-up

### 🛡️ **Security Review Process**
1. **Acknowledgment** within 48 hours
2. **Initial assessment** within 1 week
3. **Fix development** and testing
4. **Coordinated disclosure** after fix is ready
5. **Security advisory** publication

## Security Best Practices for Users

### 🔒 **Safe Usage**
- Always run the script as a regular user (not root)
- Review the script before execution if downloaded from external sources
- Use the official repository for downloads
- Keep your system updated with latest security patches

### 🚨 **Warning Signs**
Report immediately if you notice:
- Unexpected network connections
- Unauthorized file modifications outside VSCode directories
- Privilege escalation attempts beyond package installation
- Suspicious process creation or termination

### 🛠️ **Verification**
Before running the script:
```bash
# Verify script integrity
bash -n vscode-stable-updater.sh

# Check for suspicious content
grep -E "(rm -rf /|chmod 777|sudo.*NOPASSWD)" vscode-stable-updater.sh

# Review permissions
ls -la vscode-stable-updater.sh
```

## Security Audit Trail

### ✅ **Automated Security Checks**
Our CI/CD pipeline includes:
- **ShellCheck** static analysis
- **Credential scanning** for hardcoded secrets
- **Command safety** verification
- **Permission validation**
- **Multi-platform security testing**

### ✅ **Manual Security Reviews**
- Code review for all changes
- Security impact assessment
- Compliance verification against Augment Settings
- Penetration testing on supported platforms

## Compliance Certifications

### 🏆 **Augment Settings Compliance**
- ✅ Comprehensive Script Cleanup Rules
- ✅ Mandatory Truthfulness Standards
- ✅ Environment Detection Standards
- ✅ Window Targeting and Automation Verification
- ✅ Production Environment Testing Standards

### 🏆 **Industry Standards**
- ✅ OWASP Secure Coding Practices
- ✅ CIS Security Benchmarks alignment
- ✅ NIST Cybersecurity Framework principles
- ✅ Secure Software Development Lifecycle (SSDLC)

## Security Contact

For security-related questions or concerns:
- **GitHub Issues**: Use "security" label
- **Documentation**: See [SECURITY.md](SECURITY.md)
- **Updates**: Watch repository for security advisories

---

**Security is our top priority. Thank you for helping keep VSCode Stable Updater secure!**
