# VSCode Stable Updater

🚀 **Cross-platform VSCode update script with smart download management and dual-mode support**

A robust, production-ready script for updating Visual Studio Code (both Stable and Insiders editions) on Linux systems with intelligent download management, comprehensive error handling, and excellent user experience.

## ✨ Features

### 🎯 **Dual-Mode Support**
- **VSCode Stable** (default) - Production-ready releases
- **VSCode Insiders** - Latest features and updates
- **Unified UX** - Same interface for both editions
- **Smart Edition Detection** - Automatic configuration per edition

### 🌍 **Cross-Platform Support**
- **RPM-based systems**: Fedora, RHEL, CentOS, openSUSE
- **DEB-based systems**: Ubuntu, Debian, Linux Mint
- **Auto-detection**: Automatic package manager detection
- **Multi-architecture**: x86_64, aarch64/arm64, armv7l

### 🧠 **Smart Download Management**
- **Resume capability** - Continue interrupted downloads
- **Progress tracking** - Real-time download progress
- **Retry logic** - Automatic retry with exponential backoff
- **Cache management** - Persistent download cache
- **Size verification** - Integrity checking

### 🛡️ **Production-Ready Reliability**
- **Augment Cleanup Rules compliant** - Comprehensive resource management
- **Process safety** - Graceful VSCode shutdown with fallback
- **Lock file protection** - Prevents concurrent executions
- **Comprehensive logging** - Detailed operation tracking
- **Error recovery** - Robust error handling and recovery

### 🔧 **Advanced Configuration**
- **Environment variables** - Extensive customization options
- **Command-line arguments** - Flexible runtime configuration
- **Auto-install mode** - Unattended operation support
- **Debug mode** - Detailed troubleshooting information

## 🚀 Quick Start

### Basic Usage

```bash
# Update VSCode Stable (default)
./vscode-stable-updater.sh

# Update VSCode Insiders
./vscode-stable-updater.sh --edition=insiders

# Auto-install without prompts
./vscode-stable-updater.sh --auto
```

### Advanced Usage

```bash
# Debug mode with custom download directory
DEBUG=1 VSCODE_DOWNLOAD_DIR=/tmp/vscode-downloads ./vscode-stable-updater.sh

# Update Insiders with auto-install and debug
./vscode-stable-updater.sh --edition=insiders --auto --debug

# Custom configuration
DOWNLOAD_RETRIES=5 DOWNLOAD_TIMEOUT=3600 ./vscode-stable-updater.sh
```

## 📋 Requirements

### System Requirements
- **Linux distribution** with RPM or DEB package management
- **curl** - For downloading packages
- **sudo access** - For package installation
- **Internet connection** - For downloading updates

### Supported Package Managers
- **dnf** (Fedora 22+)
- **yum** (RHEL/CentOS)
- **zypper** (openSUSE)
- **apt** (Ubuntu/Debian/Mint)

### Supported Architectures
- **x86_64** - Intel/AMD 64-bit
- **aarch64/arm64** - ARM 64-bit
- **armv7l** - ARM 32-bit

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VSCODE_EDITION` | `stable` | Edition to update: `stable` or `insiders` |
| `VSCODE_BACKUP_SCRIPT` | auto-detect | Path to backup script |
| `VSCODE_DOWNLOAD_DIR` | `~/.cache/vscode-updates` | Download cache directory |
| `PARTIAL_DOWNLOAD_THRESHOLD` | `1048576` (1MB) | Size threshold for partial cleanup |
| `PROCESS_SHUTDOWN_TIMEOUT` | `5` | Seconds to wait for graceful shutdown |
| `DOWNLOAD_TIMEOUT` | `1800` (30min) | Download timeout in seconds |
| `DOWNLOAD_RETRIES` | `3` | Number of download retry attempts |
| `AUTO_INSTALL` | `0` | Skip confirmation prompts (set to `1`) |
| `DEBUG` | `0` | Enable debug logging (set to `1`) |
| `SKIP_COMPLIANCE_CHECK` | `0` | Skip Augment rules compliance check |

### Command-Line Options

```bash
Options:
  --edition=EDITION    VSCode edition: 'stable' or 'insiders' (default: stable)
  --auto              Skip confirmation prompts (auto-install mode)
  --debug             Enable debug logging
  --help, -h          Show help message
  --version, -v       Show version information
```

## 🔄 Smart Features

### Resume Interrupted Downloads
The script automatically detects partial downloads and resumes from where it left off:

```bash
# If download is interrupted at 50%, next run will resume from 50%
./vscode-stable-updater.sh
# ℹ️  Resuming download from byte 52428800 (50% complete)
```

### Automatic System Detection
No manual configuration needed - the script detects your system automatically:

```bash
# Automatically detects:
# ✅ Distribution: Fedora 38
# ✅ Package Manager: dnf
# ✅ Architecture: x86_64
# ✅ VSCode Edition: stable
```

### Graceful Process Management
Safely handles running VSCode instances:

```bash
# Options when VSCode is running:
# 1. Close VSCode automatically (recommended)
# 2. Close VSCode manually and continue  
# 3. Exit and close manually
```

## 🛡️ Safety Features

### Augment Cleanup Rules Compliance
The script follows comprehensive cleanup standards:

- ✅ **Resource tracking** - All temporary files and processes tracked
- ✅ **Signal handlers** - Proper cleanup on EXIT/INT/TERM/QUIT
- ✅ **Graceful termination** - Safe process shutdown with timeouts
- ✅ **Lock file protection** - Prevents concurrent executions
- ✅ **Secure file operations** - Ownership verification before deletion

### Backup Integration
Automatic backup detection and integration:

```bash
# Auto-detects backup scripts in common locations:
# - ~/Desktop/test/augment_chat_backup_enhanced.sh
# - ~/bin/augment_chat_backup_enhanced.sh
# - ~/.local/bin/augment_chat_backup_enhanced.sh
```

## 📊 Comparison with VSCode Insiders Updater

| Feature | Insiders Updater | **Stable Updater** |
|---------|------------------|-------------------|
| VSCode Stable Support | ❌ | ✅ |
| VSCode Insiders Support | ✅ | ✅ |
| Unified UX | ❌ | ✅ |
| Cross-Platform (RPM+DEB) | ❌ | ✅ |
| Resume Downloads | ❌ | ✅ |
| Smart Retry Logic | ❌ | ✅ |
| Augment Cleanup Compliance | ❌ | ✅ |
| Lock File Protection | ❌ | ✅ |
| Comprehensive Logging | ❌ | ✅ |
| Auto-Install Mode | ❌ | ✅ |
| Debug Mode | ❌ | ✅ |
| Backup Integration | ❌ | ✅ |

## 🔧 Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/swipswaps/vscode-stable-updater.git
cd vscode-stable-updater

# Make executable
chmod +x vscode-stable-updater.sh

# Run
./vscode-stable-updater.sh
```

### System-Wide Installation

```bash
# Install to system PATH
sudo cp vscode-stable-updater.sh /usr/local/bin/vscode-updater
sudo chmod +x /usr/local/bin/vscode-updater

# Run from anywhere
vscode-updater --edition=stable
```

## 🐛 Troubleshooting

### Enable Debug Mode
```bash
DEBUG=1 ./vscode-stable-updater.sh --debug
```

### Common Issues

**Download fails repeatedly:**
```bash
# Increase timeout and retries
DOWNLOAD_TIMEOUT=3600 DOWNLOAD_RETRIES=5 ./vscode-stable-updater.sh
```

**VSCode won't close:**
```bash
# Force close manually, then run
pkill -f code
./vscode-stable-updater.sh
```

**Permission issues:**
```bash
# Check sudo access
sudo -v
./vscode-stable-updater.sh
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

## 🔗 Related Projects

- [VSCode Insiders Updater](../vscode-insiders-updater/) - Original Insiders-only updater
- [Fedora Security Hardening Toolkit](../fedora-security-hardening-toolkit/) - System security tools

---

**Made with ❤️ for the VSCode community**
