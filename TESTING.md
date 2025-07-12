# VSCode Stable Updater - Testing Plan

⚠️ **CRITICAL**: This script is currently **UNTESTED** and should not be used in production until all tests pass.

## Testing Status

- **Current Version**: 2.0.0-alpha.1
- **Testing Status**: ❌ NOT TESTED
- **Production Ready**: ❌ NO

## Required Testing Before Production Release

### Phase 1: Basic Functionality Testing

#### 1.1 Help and Version Functions
```bash
# Test help function
./vscode-stable-updater.sh --help

# Test version function  
./vscode-stable-updater.sh --version

# Test invalid arguments
./vscode-stable-updater.sh --invalid-option
```

#### 1.2 Environment Detection Testing
```bash
# Test system detection (dry run)
DEBUG=1 SKIP_COMPLIANCE_CHECK=1 timeout 30 ./vscode-stable-updater.sh --help

# Verify detected values are correct
# - Distribution name and version
# - Package manager (dnf/yum/zypper/apt)
# - Architecture (x86_64/aarch64/armv7l)
```

#### 1.3 Edition Parameter Testing
```bash
# Test stable edition (default)
VSCODE_EDITION=stable ./vscode-stable-updater.sh --help

# Test insiders edition
VSCODE_EDITION=insiders ./vscode-stable-updater.sh --help

# Test invalid edition (should fail)
VSCODE_EDITION=invalid ./vscode-stable-updater.sh --help
```

### Phase 2: Process Management Testing

#### 2.1 VSCode Detection Testing
```bash
# Test with VSCode not running
./vscode-stable-updater.sh --auto --debug

# Test with VSCode running (if installed)
code &  # Start VSCode
./vscode-stable-updater.sh --debug
# Should detect running process and offer to close
```

#### 2.2 Lock File Testing
```bash
# Test concurrent execution prevention
./vscode-stable-updater.sh &
./vscode-stable-updater.sh  # Should fail with lock error
```

### Phase 3: Download Testing (Safe Mode)

#### 3.1 Network Connectivity Testing
```bash
# Test download info retrieval (no actual download)
DEBUG=1 timeout 60 ./vscode-stable-updater.sh --debug
# Should show download URL and file info
```

#### 3.2 Download Directory Testing
```bash
# Test custom download directory
VSCODE_DOWNLOAD_DIR=/tmp/test-downloads ./vscode-stable-updater.sh --help
# Verify directory creation and permissions
```

### Phase 4: Error Handling Testing

#### 4.1 Network Error Testing
```bash
# Test with no internet connection
# Disconnect network and run script
./vscode-stable-updater.sh --debug
# Should fail gracefully with clear error message
```

#### 4.2 Permission Error Testing
```bash
# Test with read-only download directory
mkdir -p /tmp/readonly-test
chmod 444 /tmp/readonly-test
VSCODE_DOWNLOAD_DIR=/tmp/readonly-test ./vscode-stable-updater.sh --debug
# Should fail gracefully
```

#### 4.3 Invalid URL Testing
```bash
# Test with invalid download URL (modify script temporarily)
# Should handle HTTP errors gracefully
```

### Phase 5: Platform Testing

#### 5.1 Multi-Distribution Testing
Test on each supported platform:

**RPM-based Systems:**
- [ ] Fedora 39
- [ ] Fedora 38  
- [ ] CentOS Stream 9
- [ ] openSUSE Leap

**DEB-based Systems:**
- [ ] Ubuntu 22.04
- [ ] Ubuntu 20.04
- [ ] Debian 12
- [ ] Debian 11

#### 5.2 Architecture Testing
- [ ] x86_64 (Intel/AMD 64-bit)
- [ ] aarch64 (ARM 64-bit) - if available
- [ ] armv7l (ARM 32-bit) - if available

### Phase 6: Integration Testing

#### 6.1 Full Update Cycle Testing
**⚠️ WARNING: Only test on non-production systems**

```bash
# Test complete update process
# 1. Install old version of VSCode
# 2. Run updater script
# 3. Verify new version installed
# 4. Verify VSCode still works
# 5. Verify settings preserved
```

#### 6.2 Backup Integration Testing
```bash
# Test with backup script present
# Test with backup script missing
# Verify backup creation and restoration
```

### Phase 7: Security Testing

#### 7.1 File Permission Testing
```bash
# Verify script doesn't create world-writable files
# Verify script doesn't modify files it doesn't own
# Verify script handles symlink attacks safely
```

#### 7.2 Input Validation Testing
```bash
# Test with malicious environment variables
# Test with unusual file paths
# Test with special characters in inputs
```

### Phase 8: Performance Testing

#### 8.1 Resource Usage Testing
```bash
# Monitor memory usage during execution
# Monitor CPU usage during execution
# Verify cleanup removes all temporary resources
```

#### 8.2 Large File Testing
```bash
# Test with slow network connections
# Test download resume functionality
# Test timeout handling
```

## Testing Checklist

### Pre-Testing Setup
- [ ] Create test environment (VM or container)
- [ ] Install required dependencies (curl, package managers)
- [ ] Backup any existing VSCode installation
- [ ] Document system configuration

### Testing Execution
- [ ] Phase 1: Basic Functionality ❌ NOT STARTED
- [ ] Phase 2: Process Management ❌ NOT STARTED  
- [ ] Phase 3: Download Testing ❌ NOT STARTED
- [ ] Phase 4: Error Handling ❌ NOT STARTED
- [ ] Phase 5: Platform Testing ❌ NOT STARTED
- [ ] Phase 6: Integration Testing ❌ NOT STARTED
- [ ] Phase 7: Security Testing ❌ NOT STARTED
- [ ] Phase 8: Performance Testing ❌ NOT STARTED

### Post-Testing Validation
- [ ] All tests documented with results
- [ ] All issues identified and fixed
- [ ] Version number updated to stable release
- [ ] README updated to remove alpha warnings
- [ ] Production deployment approved

## Test Results Documentation

### Test Environment
- **OS**: [To be filled]
- **Distribution**: [To be filled]
- **Architecture**: [To be filled]
- **VSCode Version**: [To be filled]
- **Test Date**: [To be filled]

### Test Results
[Results to be documented here after testing]

## Version Progression Plan

- **v2.0.0-alpha.1**: Current untested version
- **v2.0.0-alpha.2**: After basic functionality testing
- **v2.0.0-beta.1**: After platform testing
- **v2.0.0-rc.1**: After integration testing
- **v2.0.0**: After all testing complete and validated

## Testing Notes

⚠️ **IMPORTANT**: Do not use this script on production systems until all testing phases are complete and documented.

The script has been linted and follows all coding standards, but functional testing is required to ensure it works as intended in real-world scenarios.
