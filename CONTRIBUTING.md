# Contributing to VSCode Stable Updater

Thank you for your interest in contributing! This project follows strict Augment Settings compliance and quality standards.

## 🚀 Quick Start for Contributors

### Prerequisites
- **Linux system** with bash 4.0+
- **Git** for version control
- **ShellCheck** for static analysis
- **Docker** for multi-platform testing (optional)

### Development Setup
```bash
# Clone the repository
git clone https://github.com/swipswaps/vscode-stable-updater.git
cd vscode-stable-updater

# Install development dependencies
sudo apt-get install shellcheck  # Ubuntu/Debian
# OR
sudo dnf install ShellCheck      # Fedora

# Verify script syntax
bash -n vscode-stable-updater.sh

# Run basic tests
./vscode-stable-updater.sh --help
./vscode-stable-updater.sh --version
```

## 📋 Contribution Guidelines

### 🛡️ **Mandatory Augment Settings Compliance**

All contributions MUST comply with Augment Settings - Rules and User Guidelines:

#### **1. Script Cleanup Rules Compliance**
```bash
# REQUIRED: Resource tracking arrays
TEMP_FILES=()
TEMP_DIRS=()
BACKGROUND_PIDS=()
LOCK_FILES=()

# REQUIRED: Registration functions
register_temp_file() {
    TEMP_FILES+=("$1")
}

# REQUIRED: Comprehensive cleanup
cleanup_all() {
    # Graceful process termination
    # Safe file deletion with ownership verification
    # Proper error handling
}

# REQUIRED: Signal handlers
trap cleanup_all EXIT INT TERM QUIT
```

#### **2. Truthfulness Standards Compliance**
- ✅ **Never ignore errors** - All errors must be acknowledged
- ✅ **Consistent capabilities** - No contradictory claims
- ✅ **Accurate reporting** - Truthful automation results
- ✅ **Proper verification** - Verify before claiming success

#### **3. Environment Detection Standards**
- ✅ **Programmatic verification** - Use `command -v`, environment variables
- ✅ **No package assumptions** - Don't infer environment from installed packages
- ✅ **Multi-layer detection** - Verify distribution, package manager, architecture
- ✅ **Comprehensive support** - Cover all major Linux distributions

### 🔍 **Code Quality Standards**

#### **Static Analysis Requirements**
```bash
# REQUIRED: Pass ShellCheck
shellcheck -x vscode-stable-updater.sh

# REQUIRED: Pass syntax check
bash -n vscode-stable-updater.sh

# REQUIRED: No security issues
grep -E "(rm -rf /|chmod 777|sudo.*NOPASSWD)" vscode-stable-updater.sh
# Should return no matches
```

#### **Testing Requirements**
```bash
# REQUIRED: Test help function
./vscode-stable-updater.sh --help

# REQUIRED: Test version function
./vscode-stable-updater.sh --version

# REQUIRED: Test edition validation
VSCODE_EDITION=stable ./vscode-stable-updater.sh --help
VSCODE_EDITION=insiders ./vscode-stable-updater.sh --help

# REQUIRED: Test invalid input handling
! VSCODE_EDITION=invalid ./vscode-stable-updater.sh --help
```

### 📝 **Documentation Standards**

#### **Code Documentation**
- **Function headers** - Describe purpose, parameters, return values
- **Complex logic** - Explain non-obvious code sections
- **Error conditions** - Document all error scenarios
- **Configuration** - Document all environment variables

#### **Commit Message Format**
```
type(scope): brief description

Detailed explanation of changes including:
- What was changed and why
- Augment Settings compliance verification
- Testing performed
- Breaking changes (if any)

Closes #issue-number
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 🧪 **Testing Requirements**

#### **Pre-Submission Checklist**
- [ ] **Syntax validation** - `bash -n vscode-stable-updater.sh`
- [ ] **ShellCheck compliance** - `shellcheck -x vscode-stable-updater.sh`
- [ ] **Security scan** - No hardcoded credentials or unsafe commands
- [ ] **Functionality test** - Help, version, and basic operations work
- [ ] **Augment compliance** - All rules followed
- [ ] **Documentation updated** - README, comments, and help text

#### **Multi-Platform Testing**
Test on at least 2 of these platforms:
- Ubuntu 22.04 / 20.04
- Debian 12 / 11
- Fedora 39 / 38
- CentOS Stream 9

#### **CI/CD Pipeline**
All pull requests automatically run:
- **Lint and validate** - ShellCheck and syntax
- **Compliance testing** - Augment rules verification
- **Multi-distro testing** - 6 Linux distributions
- **Security scanning** - Vulnerability detection
- **Documentation checks** - README and LICENSE validation

## 🔄 **Development Workflow**

### **1. Issue Creation**
- **Bug reports** - Include reproduction steps, environment details
- **Feature requests** - Explain use case, proposed implementation
- **Security issues** - Use "security" label, follow responsible disclosure

### **2. Development Process**
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes following compliance standards
# ... development work ...

# Test thoroughly
bash -n vscode-stable-updater.sh
shellcheck -x vscode-stable-updater.sh
./vscode-stable-updater.sh --help

# Commit with proper message
git commit -m "feat(updater): add new feature

- Implement feature X for better Y
- Maintain Augment Settings compliance
- Add comprehensive error handling
- Update documentation

Closes #123"

# Push and create pull request
git push origin feature/your-feature-name
```

### **3. Pull Request Process**
1. **Create PR** with detailed description
2. **Automated testing** runs on CI/CD
3. **Code review** by maintainers
4. **Compliance verification** against Augment Settings
5. **Merge** after approval and passing tests

## 🏆 **Recognition**

### **Contributor Types**
- **Code contributors** - Feature development, bug fixes
- **Documentation contributors** - README, guides, examples
- **Testing contributors** - Platform testing, issue reproduction
- **Security contributors** - Vulnerability reports, security improvements

### **Acknowledgment**
- Contributors listed in README
- GitHub contributor statistics
- Special recognition for significant contributions

## 🚫 **What We Don't Accept**

- **Non-compliant code** - Must follow Augment Settings
- **Unsafe operations** - No dangerous commands or practices
- **Breaking changes** - Without proper deprecation and migration path
- **Untested code** - All changes must be tested
- **Poor documentation** - Code must be properly documented

## 📞 **Getting Help**

### **Development Questions**
- **GitHub Discussions** - General development questions
- **GitHub Issues** - Bug reports and feature requests
- **Code Review** - Comments on pull requests

### **Compliance Questions**
- **Augment Settings** - Refer to `.augment/rules/` directory
- **Security Standards** - See [SECURITY.md](SECURITY.md)
- **Testing Standards** - Check CI/CD pipeline configuration

## 📄 **License**

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to VSCode Stable Updater!**
**Together we build better, safer, and more reliable software.**
