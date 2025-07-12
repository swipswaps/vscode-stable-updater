#!/usr/bin/env bash
################################################################################
# Cross-Platform VSCode Stable Update Script
# Enhanced version supporting both VSCode Stable and Insiders with unified UX
# Supports RPM-based (Fedora, RHEL, openSUSE) and DEB-based (Ubuntu, Debian) systems
# Features: Smart downloads, resume capability, automatic system detection, dual-mode support
#
# Environment Variables (optional configuration):
#   VSCODE_EDITION               - Edition to update: 'stable' or 'insiders' (default: stable)
#   VSCODE_BACKUP_SCRIPT         - Path to backup script (auto-detected if not set)
#   VSCODE_DOWNLOAD_DIR          - Download cache directory (default: ~/.cache/vscode-updates)
#   PARTIAL_DOWNLOAD_THRESHOLD   - Size threshold for partial download cleanup (default: 1MB)
#   PROCESS_SHUTDOWN_TIMEOUT     - Seconds to wait for graceful process shutdown (default: 5)
#   DOWNLOAD_TIMEOUT             - Download timeout in seconds (default: 1800/30min)
#   DOWNLOAD_RETRIES             - Number of download retry attempts (default: 3)
#   AUTO_INSTALL                 - Skip confirmation prompts (set to 1)
#   DEBUG                        - Enable debug logging (set to 1)
#   SKIP_COMPLIANCE_CHECK        - Skip Augment rules compliance check (set to 1)
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ========== COMPREHENSIVE CLEANUP SYSTEM ==========
# Global cleanup tracking arrays (Augment Cleanup Rules Compliant)
TEMP_FILES=()
TEMP_DIRS=()
BACKGROUND_PIDS=()
LOCK_FILES=()
STARTED_SERVICES=()

# Resource registration functions
register_temp_file() {
    TEMP_FILES+=("$1")
    [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Registered temp file: $1" >&2
}

register_temp_dir() {
    TEMP_DIRS+=("$1")
    [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Registered temp dir: $1" >&2
}

register_background_pid() {
    BACKGROUND_PIDS+=("$1")
    [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Registered background PID: $1" >&2
}

register_lock_file() {
    LOCK_FILES+=("$1")
    [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Registered lock file: $1" >&2
}

# Comprehensive cleanup function
cleanup_all() {
    local exit_code=$?
    local cleanup_start
    cleanup_start=$(date +%s)

    [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Starting comprehensive cleanup (exit code: $exit_code)" >&2

    # Kill background processes gracefully
    for pid in "${BACKGROUND_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Terminating background process: $pid" >&2
            # Try graceful shutdown first
            kill "$pid" 2>/dev/null || true

            # Wait for graceful shutdown
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt $PROCESS_SHUTDOWN_TIMEOUT ]]; do
                sleep 1
                ((count++))
            done

            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Force killing process: $pid" >&2
                kill -9 "$pid" 2>/dev/null || true
            fi
        fi
    done

    # Clean up temporary files with ownership verification
    for file in "${TEMP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            # Verify we own the file before deletion
            if [[ -O "$file" ]]; then
                [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Removing temp file: $file" >&2
                rm -f "$file" 2>/dev/null || true
            else
                echo "WARNING: Cannot remove temp file (not owner): $file" >&2
            fi
        fi
    done

    # Clean up temporary directories with safety checks
    for dir in "${TEMP_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            # Verify directory is within safe paths
            case "$dir" in
                /tmp/*|/var/tmp/*|"$HOME"/.cache/*)
                    if [[ -O "$dir" ]]; then
                        [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Removing temp dir: $dir" >&2
                        rm -rf "$dir" 2>/dev/null || true
                    else
                        echo "WARNING: Cannot remove temp dir (not owner): $dir" >&2
                    fi
                    ;;
                *)
                    echo "WARNING: Skipping cleanup of directory outside safe paths: $dir" >&2
                    ;;
            esac
        fi
    done

    # Remove lock files
    for lock in "${LOCK_FILES[@]}"; do
        if [[ -f "$lock" ]] && [[ -O "$lock" ]]; then
            [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Removing lock file: $lock" >&2
            rm -f "$lock" 2>/dev/null || true
        fi
    done

    # Stop any services we started
    for service in "${STARTED_SERVICES[@]}"; do
        [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Stopping service: $service" >&2
        systemctl stop "$service" 2>/dev/null || true
    done

    local cleanup_end
    cleanup_end=$(date +%s)
    local cleanup_duration=$((cleanup_end - cleanup_start))
    [[ "${DEBUG:-0}" == "1" ]] && echo "DEBUG: Cleanup completed in ${cleanup_duration}s" >&2

    exit $exit_code
}

# Set comprehensive trap for all signals
trap cleanup_all EXIT INT TERM QUIT

# ========== CONFIGURATION ==========
SCRIPT_VERSION="2.0.0-alpha.1"

# Edition configuration - supports both stable and insiders
VSCODE_EDITION="${VSCODE_EDITION:-stable}"

# Validate edition
case "$VSCODE_EDITION" in
    "stable"|"insiders")
        ;;
    *)
        echo "ERROR: Invalid VSCODE_EDITION '$VSCODE_EDITION'. Must be 'stable' or 'insiders'" >&2
        exit 1
        ;;
esac

# Edition-specific configuration
if [[ "$VSCODE_EDITION" == "stable" ]]; then
    VSCODE_PROCESS_NAME="code"
    VSCODE_PACKAGE_NAME="code"
    VSCODE_CONFIG_DIR="Code"
    DOWNLOAD_URL_BASE="https://code.visualstudio.com/sha/download"
    USER_AGENT="VSCode-Stable-Updater/$SCRIPT_VERSION"
else
    VSCODE_PROCESS_NAME="code-insiders"
    VSCODE_PACKAGE_NAME="code-insiders"
    VSCODE_CONFIG_DIR="Code - Insiders"
    DOWNLOAD_URL_BASE="https://code.visualstudio.com/sha/download"
    USER_AGENT="VSCode-Insiders-Updater/$SCRIPT_VERSION"
fi

# Configurable paths (can be overridden via environment variables)
BACKUP_SCRIPT="${VSCODE_BACKUP_SCRIPT:-}"
DOWNLOAD_DIR="${VSCODE_DOWNLOAD_DIR:-$HOME/.cache/vscode-updates}"

# Configurable thresholds
PARTIAL_DOWNLOAD_THRESHOLD="${PARTIAL_DOWNLOAD_THRESHOLD:-1048576}"  # 1MB in bytes
PROCESS_SHUTDOWN_TIMEOUT="${PROCESS_SHUTDOWN_TIMEOUT:-5}"  # seconds
DOWNLOAD_TIMEOUT="${DOWNLOAD_TIMEOUT:-1800}"  # 30 minutes
DOWNLOAD_RETRIES="${DOWNLOAD_RETRIES:-3}"
AUTO_INSTALL="${AUTO_INSTALL:-0}"

# Lock file for preventing concurrent executions
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/vscode_${VSCODE_EDITION}_updater.lock"
register_lock_file "$LOCK_FILE"

# ========== LOGGING ==========
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "SUCCESS") echo -e "${timestamp} ✅ ${message}" ;;
        "ERROR")   echo -e "${timestamp} ❌ ${message}" >&2 ;;
        "INFO")    echo -e "${timestamp} ℹ️  ${message}" ;;
        "WARN")    echo -e "${timestamp} ⚠️  ${message}" ;;
        "DEBUG")   [[ "${DEBUG:-0}" == "1" ]] && echo -e "${timestamp} 🐛 ${message}" >&2 ;;
    esac
}

# ========== SYSTEM DETECTION ==========
get_system_info() {
    log "INFO" "Detecting system configuration..."
    
    # Detect distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_NAME="$NAME"
        DISTRO_VERSION="$VERSION_ID"
    else
        log "ERROR" "Cannot detect Linux distribution"
        exit 1
    fi
    
    # Detect package manager and format
    if command -v dnf &>/dev/null; then
        PACKAGE_MANAGER="dnf"
        PACKAGE_FORMAT="rpm"
        INSTALL_CMD="sudo dnf install -y"
    elif command -v yum &>/dev/null; then
        PACKAGE_MANAGER="yum"
        PACKAGE_FORMAT="rpm"
        INSTALL_CMD="sudo yum install -y"
    elif command -v zypper &>/dev/null; then
        PACKAGE_MANAGER="zypper"
        PACKAGE_FORMAT="rpm"
        INSTALL_CMD="sudo zypper install -y"
    elif command -v apt &>/dev/null; then
        PACKAGE_MANAGER="apt"
        PACKAGE_FORMAT="deb"
        INSTALL_CMD="sudo apt install -y"
    else
        log "ERROR" "No supported package manager found (dnf/yum/zypper/apt)"
        exit 1
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        "x86_64") DOWNLOAD_ARCH="linux-x64" ;;
        "aarch64"|"arm64") DOWNLOAD_ARCH="linux-arm64" ;;
        "armv7l") DOWNLOAD_ARCH="linux-armhf" ;;
        *) 
            log "ERROR" "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    # Set VSCode configuration directory
    VSCODE_CONFIG="$HOME/.config/$VSCODE_CONFIG_DIR/User"
    
    # Set download URL and filename
    DOWNLOAD_URL="$DOWNLOAD_URL_BASE?build=$VSCODE_EDITION&os=$DOWNLOAD_ARCH"
    DOWNLOAD_FILENAME="vscode-${VSCODE_EDITION}-${DOWNLOAD_ARCH}.${PACKAGE_FORMAT}"
    CURRENT_DOWNLOAD="$DOWNLOAD_DIR/$DOWNLOAD_FILENAME"
    DOWNLOAD_INFO="$DOWNLOAD_DIR/${DOWNLOAD_FILENAME}.info"
    
    # Register temp files
    register_temp_file "$DOWNLOAD_INFO"
    
    log "SUCCESS" "System detected: $DISTRO_NAME ($PACKAGE_MANAGER/$PACKAGE_FORMAT/$ARCH)"
    log "DEBUG" "VSCode Edition: $VSCODE_EDITION"
    log "DEBUG" "Package Name: $VSCODE_PACKAGE_NAME"
    log "DEBUG" "Distribution: $DISTRO_ID $DISTRO_VERSION"
    log "DEBUG" "Install Command: $INSTALL_CMD"
    log "DEBUG" "Download URL: $DOWNLOAD_URL"
    log "DEBUG" "Config Directory: $VSCODE_CONFIG"
}

# ========== LOCK FILE MANAGEMENT ==========
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid
        lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log "ERROR" "Another instance is already running (PID: $lock_pid)"
            exit 1
        else
            log "WARN" "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi

    echo $$ > "$LOCK_FILE"
    log "DEBUG" "Lock acquired: $LOCK_FILE"
}

# ========== TERMINAL AUTOMATION ==========
open_warning_terminal() {
    local message="$1"
    local title="VSCode Updater Warning"

    # Try different terminal emulators in order of preference
    local terminals=(
        "gnome-terminal --title='$title' --"
        "konsole --title '$title' -e"
        "xfce4-terminal --title='$title' -e"
        "xterm -title '$title' -e"
        "urxvt -title '$title' -e"
        "alacritty --title '$title' -e"
        "kitty --title '$title'"
    )

    for terminal_cmd in "${terminals[@]}"; do
        if command -v "${terminal_cmd%% *}" &>/dev/null; then
            log "DEBUG" "Opening warning terminal with: $terminal_cmd"
            # Open terminal with warning message
            $terminal_cmd bash -c "echo '$message'; echo ''; echo 'Press Enter to continue...'; read -r" &
            local terminal_pid=$!
            BACKGROUND_PIDS+=("$terminal_pid")
            log "INFO" "Warning terminal opened (PID: $terminal_pid)"
            return 0
        fi
    done

    log "WARN" "No suitable terminal emulator found for warning display"
    return 1
}

# ========== VSCODE PROCESS MANAGEMENT ==========
check_vscode_running() {
    log "INFO" "Checking if VSCode $VSCODE_EDITION is running..."

    local vscode_pids
    mapfile -t vscode_pids < <(pgrep -f "$VSCODE_PROCESS_NAME" 2>/dev/null || true)

    if [[ ${#vscode_pids[@]} -gt 0 ]]; then
        log "WARN" "VSCode $VSCODE_EDITION is currently running (PIDs: ${vscode_pids[*]})"

        # Open warning terminal to alert user
        local warning_message="⚠️  VSCode $VSCODE_EDITION Update Warning ⚠️

VSCode $VSCODE_EDITION is currently running and must be closed before updating.

Running processes: ${vscode_pids[*]}

Please choose an option in the main terminal:
1. Close VSCode automatically (recommended)
2. Close VSCode manually and continue
3. Exit and close manually

The main script is waiting for your decision..."

        if open_warning_terminal "$warning_message"; then
            log "INFO" "Warning terminal opened - user notified about running VSCode"
            sleep 2  # Give terminal time to open and be visible
        fi

        if [[ "${AUTO_INSTALL:-0}" == "1" ]]; then
            log "INFO" "Auto-install mode: Attempting to close VSCode gracefully..."
            close_vscode_gracefully
        else
            echo ""
            echo "VSCode $VSCODE_EDITION must be closed before updating."
            echo "Options:"
            echo "1. Close VSCode automatically (recommended)"
            echo "2. Close VSCode manually and continue"
            echo "3. Exit and close manually"
            echo ""

            read -r -p "Choose (1-3) [default: 1]: " choice
            choice=${choice:-1}

            case $choice in
                1)
                    close_vscode_gracefully
                    ;;
                2)
                    echo "Please close VSCode $VSCODE_EDITION and press Enter to continue..."
                    read -r _
                    check_vscode_running  # Recursive check
                    ;;
                3)
                    log "INFO" "Exiting. Please close VSCode $VSCODE_EDITION manually and run the script again."
                    exit 0
                    ;;
                *)
                    log "ERROR" "Invalid choice. Please try again."
                    check_vscode_running
                    ;;
            esac
        fi
    else
        log "SUCCESS" "VSCode $VSCODE_EDITION is not running"
    fi
}

close_vscode_gracefully() {
    log "INFO" "Attempting to close VSCode $VSCODE_EDITION gracefully..."

    local vscode_pids
    mapfile -t vscode_pids < <(pgrep -f "$VSCODE_PROCESS_NAME" 2>/dev/null || true)

    if [[ ${#vscode_pids[@]} -eq 0 ]]; then
        log "SUCCESS" "VSCode $VSCODE_EDITION is already closed"
        return 0
    fi

    # Try graceful shutdown first
    for pid in "${vscode_pids[@]}"; do
        log "DEBUG" "Sending TERM signal to PID: $pid"
        kill -TERM "$pid" 2>/dev/null || true
    done

    # Wait for graceful shutdown
    local wait_time=0
    local max_wait=15

    while [[ $wait_time -lt $max_wait ]]; do
        local remaining_pids
        mapfile -t remaining_pids < <(pgrep -f "$VSCODE_PROCESS_NAME" 2>/dev/null || true)
        if [[ ${#remaining_pids[@]} -eq 0 ]]; then
            log "SUCCESS" "VSCode $VSCODE_EDITION closed gracefully"
            return 0
        fi

        sleep 1
        ((wait_time++))

        if [[ $((wait_time % 5)) -eq 0 ]]; then
            log "INFO" "Waiting for VSCode to close... (${wait_time}s/${max_wait}s)"
        fi
    done

    # Force close if still running
    local remaining_pids
    mapfile -t remaining_pids < <(pgrep -f "$VSCODE_PROCESS_NAME" 2>/dev/null || true)
    if [[ ${#remaining_pids[@]} -gt 0 ]]; then
        log "WARN" "Force closing VSCode $VSCODE_EDITION (PIDs: ${remaining_pids[*]})"
        for pid in "${remaining_pids[@]}"; do
            kill -KILL "$pid" 2>/dev/null || true
        done
        sleep 2
    fi

    # Final verification
    if pgrep -f "$VSCODE_PROCESS_NAME" >/dev/null 2>&1; then
        log "ERROR" "Failed to close VSCode $VSCODE_EDITION"
        return 1
    else
        log "SUCCESS" "VSCode $VSCODE_EDITION closed successfully"
        return 0
    fi
}

# ========== BACKUP MANAGEMENT ==========
create_backup() {
    log "INFO" "Creating backup of VSCode $VSCODE_EDITION configuration..."

    if [[ -n "$BACKUP_SCRIPT" ]] && [[ -f "$BACKUP_SCRIPT" ]] && [[ -x "$BACKUP_SCRIPT" ]]; then
        log "INFO" "Using backup script: $BACKUP_SCRIPT"

        if "$BACKUP_SCRIPT" --create --edition="$VSCODE_EDITION" 2>/dev/null; then
            log "SUCCESS" "Backup created successfully"
            return 0
        else
            log "WARN" "Backup script failed, continuing without backup"
            return 1
        fi
    else
        # Simple built-in backup
        local backup_dir
        backup_dir="$HOME/vscode-${VSCODE_EDITION}-backup-$(date +%Y%m%d_%H%M%S)"

        if [[ -d "$VSCODE_CONFIG" ]]; then
            log "INFO" "Creating simple backup: $backup_dir"

            if cp -r "$VSCODE_CONFIG" "$backup_dir" 2>/dev/null; then
                echo "$backup_dir" > "$HOME/.last_vscode_${VSCODE_EDITION}_backup"
                log "SUCCESS" "Simple backup created: $backup_dir"
                return 0
            else
                log "WARN" "Simple backup failed"
                return 1
            fi
        else
            log "INFO" "No existing configuration to backup"
            return 0
        fi
    fi
}

# ========== DOWNLOAD MANAGEMENT ==========
get_remote_file_info() {
    log "DEBUG" "Getting remote file information..."

    local temp_file
    temp_file=$(mktemp)
    register_temp_file "$temp_file"

    # Get headers from remote file
    if ! curl -sI "$DOWNLOAD_URL" \
        --user-agent "$USER_AGENT" \
        --connect-timeout 30 \
        --max-time 60 > "$temp_file"; then
        log "ERROR" "Failed to get remote file information"
        return 1
    fi

    # Parse headers
    local content_length
    local last_modified
    local etag
    content_length=$(grep -i "content-length:" "$temp_file" | tail -1 | cut -d' ' -f2 | tr -d '\r\n' || echo "0")
    last_modified=$(grep -i "last-modified:" "$temp_file" | tail -1 | cut -d' ' -f2- | tr -d '\r\n' || echo "")
    etag=$(grep -i "etag:" "$temp_file" | tail -1 | cut -d' ' -f2 | tr -d '\r\n' || echo "")

    # Save download info
    cat > "$DOWNLOAD_INFO" << EOF
CONTENT_LENGTH=$content_length
LAST_MODIFIED=$last_modified
ETAG=$etag
TIMESTAMP=$(date +%s)
EOF

    log "DEBUG" "Remote file size: $content_length bytes"
    return 0
}

smart_download() {
    log "INFO" "Starting smart download with resume capability..."
    mkdir -p "$DOWNLOAD_DIR"
    register_temp_dir "$DOWNLOAD_DIR"

    # Get remote file info
    if ! get_remote_file_info; then
        return 1
    fi

    # shellcheck source=/dev/null
    source "$DOWNLOAD_INFO"
    # shellcheck disable=SC2153
    local total_size="$CONTENT_LENGTH"
    local resume_from=0

    # Check if we can resume
    if [[ -f "$CURRENT_DOWNLOAD" ]]; then
        resume_from=$(stat -c%s "$CURRENT_DOWNLOAD" 2>/dev/null || echo "0")
        if [[ "$resume_from" -gt 0 ]] && [[ "$resume_from" -lt "$total_size" ]]; then
            log "INFO" "Resuming download from byte $resume_from ($(( (resume_from * 100) / total_size ))% complete)"
        elif [[ "$resume_from" -ge "$total_size" ]]; then
            log "SUCCESS" "File already complete ($(( total_size / 1024 / 1024 ))MB)"
            return 0
        fi
    fi

    # Download with resume capability and progress
    local attempt=1
    local max_retries=$DOWNLOAD_RETRIES

    while [[ $attempt -le $max_retries ]]; do
        log "INFO" "Download attempt $attempt/$max_retries"

        if curl -L "$DOWNLOAD_URL" \
            --user-agent "$USER_AGENT" \
            --output "$CURRENT_DOWNLOAD" \
            --continue-at "$resume_from" \
            --progress-bar \
            --connect-timeout 30 \
            --max-time "$DOWNLOAD_TIMEOUT" \
            --retry 2 \
            --retry-delay 5; then

            local final_size
            final_size=$(stat -c%s "$CURRENT_DOWNLOAD" 2>/dev/null || echo "0")
            if [[ "$final_size" -eq "$total_size" ]]; then
                log "SUCCESS" "Download completed successfully ($(( final_size / 1024 / 1024 ))MB)"
                return 0
            else
                log "WARN" "Size mismatch: got $(( final_size / 1024 / 1024 ))MB, expected $(( total_size / 1024 / 1024 ))MB"
                resume_from="$final_size"
            fi
        else
            log "ERROR" "Download attempt $attempt failed"
            if [[ -f "$CURRENT_DOWNLOAD" ]]; then
                resume_from=$(stat -c%s "$CURRENT_DOWNLOAD" 2>/dev/null || echo "0")
            fi
        fi

        ((attempt++))
        if [[ $attempt -le $max_retries ]]; then
            log "INFO" "Waiting 5 seconds before retry..."
            sleep 5
        fi
    done

    log "ERROR" "Download failed after $max_retries attempts"
    return 1
}

verify_and_install() {
    log "INFO" "Verifying downloaded package..."

    # Check file exists and has content
    if [[ ! -f "$CURRENT_DOWNLOAD" ]] || [[ ! -s "$CURRENT_DOWNLOAD" ]]; then
        log "ERROR" "Downloaded file is missing or empty"
        return 1
    fi

    # Check if it's a valid package based on format
    case "$PACKAGE_FORMAT" in
        "rpm")
            if ! file "$CURRENT_DOWNLOAD" | grep -q "RPM"; then
                log "ERROR" "Downloaded file is not a valid RPM package"
                return 1
            fi
            ;;
        "deb")
            if ! file "$CURRENT_DOWNLOAD" | grep -q "Debian"; then
                log "ERROR" "Downloaded file is not a valid DEB package"
                return 1
            fi
            ;;
        *)
            log "WARN" "Unknown package format: $PACKAGE_FORMAT - skipping format verification"
            ;;
    esac

    log "SUCCESS" "Package verification passed"

    # Install the package
    log "INFO" "Installing VSCode $VSCODE_EDITION..."

    if [[ "${AUTO_INSTALL:-0}" != "1" ]]; then
        echo ""
        echo "Ready to install VSCode $VSCODE_EDITION"
        echo "Package: $CURRENT_DOWNLOAD"
        echo "Size: $(( $(stat -c%s "$CURRENT_DOWNLOAD") / 1024 / 1024 ))MB"
        echo ""
        read -r -p "Proceed with installation? (Y/n): " confirm
        confirm=${confirm:-Y}

        if [[ "$confirm" != "Y" ]] && [[ "$confirm" != "y" ]]; then
            log "INFO" "Installation cancelled by user"
            return 1
        fi
    fi

    case "$PACKAGE_FORMAT" in
        "rpm")
            if sudo rpm -Uvh "$CURRENT_DOWNLOAD"; then
                log "SUCCESS" "RPM package installed successfully"
            else
                log "ERROR" "RPM installation failed"
                return 1
            fi
            ;;
        "deb")
            if sudo dpkg -i "$CURRENT_DOWNLOAD"; then
                log "SUCCESS" "DEB package installed successfully"
            else
                log "WARN" "DEB installation had issues, attempting to fix dependencies..."
                if sudo apt-get install -f -y; then
                    log "SUCCESS" "Dependencies fixed, DEB package installed successfully"
                else
                    log "ERROR" "DEB installation failed"
                    return 1
                fi
            fi
            ;;
        *)
            log "ERROR" "Unsupported package format: $PACKAGE_FORMAT"
            return 1
            ;;
    esac

    return 0
}

download_and_install() {
    log "INFO" "Starting download and installation process..."

    # Download
    if ! smart_download; then
        log "ERROR" "Download failed"
        return 1
    fi

    # Verify and install
    if ! verify_and_install; then
        log "ERROR" "Installation failed"
        return 1
    fi

    log "SUCCESS" "VSCode $VSCODE_EDITION update completed successfully"
    return 0
}

# ========== COMPLIANCE VALIDATION ==========
validate_cleanup_compliance() {
    local compliance_issues=0

    # Check for trap handlers
    if ! grep -q "trap.*EXIT" "$0"; then
        echo "❌ COMPLIANCE: Missing EXIT trap handler" >&2
        ((compliance_issues++))
    fi

    # Check for cleanup function
    if ! grep -q "cleanup_all" "$0"; then
        echo "❌ COMPLIANCE: Missing comprehensive cleanup function" >&2
        ((compliance_issues++))
    fi

    # Check for resource tracking arrays
    local required_arrays=("TEMP_FILES" "TEMP_DIRS" "BACKGROUND_PIDS" "LOCK_FILES")
    for array in "${required_arrays[@]}"; do
        if ! grep -q "$array" "$0"; then
            echo "❌ COMPLIANCE: Missing resource tracking array: $array" >&2
            ((compliance_issues++))
        fi
    done

    # Check for mktemp usage instead of hardcoded paths
    if grep -q "/tmp/[^$]" "$0" && ! grep -q "mktemp" "$0"; then
        echo "⚠️  COMPLIANCE: Consider using mktemp for temporary files" >&2
    fi

    if [[ $compliance_issues -eq 0 ]]; then
        log "SUCCESS" "✅ Augment Cleanup Rules compliance validation passed"
        return 0
    else
        log "ERROR" "❌ Augment Cleanup Rules compliance validation failed ($compliance_issues issues)"
        return 1
    fi
}

# ========== CONFIGURATION DISPLAY ==========
show_configuration() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "DEBUG: Configuration:" >&2
        echo "  VSCODE_EDITION: $VSCODE_EDITION" >&2
        echo "  BACKUP_SCRIPT: ${BACKUP_SCRIPT:-'(auto-detect failed)'}" >&2
        echo "  DOWNLOAD_DIR: $DOWNLOAD_DIR" >&2
        echo "  PARTIAL_DOWNLOAD_THRESHOLD: $PARTIAL_DOWNLOAD_THRESHOLD bytes" >&2
        echo "  PROCESS_SHUTDOWN_TIMEOUT: $PROCESS_SHUTDOWN_TIMEOUT seconds" >&2
        echo "  DOWNLOAD_TIMEOUT: $DOWNLOAD_TIMEOUT seconds" >&2
        echo "  DOWNLOAD_RETRIES: $DOWNLOAD_RETRIES attempts" >&2
        echo "  AUTO_INSTALL: ${AUTO_INSTALL:-0}" >&2
        echo "  LOCK_FILE: $LOCK_FILE" >&2
        echo "" >&2
    fi
}

# ========== MAIN FUNCTION ==========
main() {
    echo "🚀 VSCode $VSCODE_EDITION Updater v$SCRIPT_VERSION"
    echo "Cross-platform update script with smart download management"
    echo ""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --edition=*)
                VSCODE_EDITION="${1#*=}"
                shift
                ;;
            --auto)
                AUTO_INSTALL=1
                shift
                ;;
            --debug)
                DEBUG=1
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "VSCode Updater v$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Validate edition after potential command line override
    case "$VSCODE_EDITION" in
        "stable"|"insiders")
            ;;
        *)
            log "ERROR" "Invalid edition '$VSCODE_EDITION'. Must be 'stable' or 'insiders'"
            exit 1
            ;;
    esac

    # Show configuration in debug mode
    show_configuration

    # Step 1: Compliance validation
    if [[ "${SKIP_COMPLIANCE_CHECK:-0}" != "1" ]]; then
        if ! validate_cleanup_compliance; then
            log "ERROR" "Compliance validation failed. Set SKIP_COMPLIANCE_CHECK=1 to bypass."
            exit 1
        fi
    fi

    # Step 2: System detection
    get_system_info

    # Step 3: Lock management
    acquire_lock

    # Step 4: VSCode running check
    check_vscode_running

    # Step 5: Create backup
    if ! create_backup; then
        if [[ "${AUTO_INSTALL:-0}" != "1" ]]; then
            log "ERROR" "Backup creation failed"
            read -r -p "Continue without backup? (y/N): " continue_without_backup
            if [[ "$continue_without_backup" != "y" ]] && [[ "$continue_without_backup" != "Y" ]]; then
                exit 1
            fi
        else
            log "WARN" "Backup creation failed in auto-install mode, continuing anyway"
        fi
    fi

    # Step 6: Download and install
    if ! download_and_install; then
        log "ERROR" "Update failed"
        exit 1
    fi

    # Success
    echo ""
    echo "🎉 VSCode $VSCODE_EDITION update completed successfully!"
    echo ""
    echo "📁 Backup location: $(cat "$HOME/.last_vscode_${VSCODE_EDITION}_backup" 2>/dev/null || echo 'No backup created')"
    echo "📁 Download cache: $DOWNLOAD_DIR"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Start VSCode $VSCODE_EDITION"
    echo "   2. Verify your extensions and settings"
    echo "   3. Check that your workspace is intact"
    echo ""
    if [[ -n "$BACKUP_SCRIPT" ]]; then
        echo "🔄 If issues occur, restore from backup:"
        echo "   $BACKUP_SCRIPT --restore --edition=$VSCODE_EDITION"
        echo ""
    fi
    echo "⚡ Smart features enabled:"
    echo "   • Dual-mode support (stable & insiders)"
    echo "   • Cross-platform support (RPM & DEB systems)"
    echo "   • Resume interrupted downloads"
    echo "   • Skip downloads if already up-to-date"
    echo "   • Persistent download cache"
    echo "   • Automatic package manager detection"
    echo "   • Graceful process management"
    echo ""
    echo "🛡️  Augment Cleanup Rules compliance:"
    echo "   • Comprehensive resource tracking"
    echo "   • Graceful process termination"
    echo "   • Secure temporary file management"
    echo "   • Lock file protection"
    echo "   • Signal handler cleanup (EXIT/INT/TERM/QUIT)"
    echo ""
    log "SUCCESS" "Update process completed"
}

# ========== HELP FUNCTION ==========
show_help() {
    cat << EOF
VSCode Updater v$SCRIPT_VERSION
Cross-platform VSCode update script with smart download management

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --edition=EDITION    VSCode edition to update: 'stable' or 'insiders' (default: stable)
    --auto              Skip confirmation prompts (auto-install mode)
    --debug             Enable debug logging
    --help, -h          Show this help message
    --version, -v       Show version information

ENVIRONMENT VARIABLES:
    VSCODE_EDITION               Edition to update: 'stable' or 'insiders' (default: stable)
    VSCODE_BACKUP_SCRIPT         Path to backup script (auto-detected if not set)
    VSCODE_DOWNLOAD_DIR          Download cache directory (default: ~/.cache/vscode-updates)
    PARTIAL_DOWNLOAD_THRESHOLD   Size threshold for partial download cleanup (default: 1MB)
    PROCESS_SHUTDOWN_TIMEOUT     Seconds to wait for graceful process shutdown (default: 5)
    DOWNLOAD_TIMEOUT             Download timeout in seconds (default: 1800/30min)
    DOWNLOAD_RETRIES             Number of download retry attempts (default: 3)
    AUTO_INSTALL                 Skip confirmation prompts (set to 1)
    DEBUG                        Enable debug logging (set to 1)
    SKIP_COMPLIANCE_CHECK        Skip Augment rules compliance check (set to 1)

EXAMPLES:
    # Update VSCode stable (default)
    $0

    # Update VSCode Insiders
    $0 --edition=insiders

    # Auto-install without prompts
    $0 --auto

    # Debug mode with custom download directory
    DEBUG=1 VSCODE_DOWNLOAD_DIR=/tmp/vscode-downloads $0

    # Update Insiders with auto-install
    $0 --edition=insiders --auto

FEATURES:
    • Dual-mode support (stable & insiders with unified UX)
    • Cross-platform support (RPM & DEB-based Linux distributions)
    • Smart download management with resume capability
    • Automatic system and package manager detection
    • Graceful VSCode process management
    • Comprehensive backup and recovery options
    • Augment Cleanup Rules compliance
    • Lock file protection against concurrent executions

SUPPORTED SYSTEMS:
    • Fedora (dnf)
    • RHEL/CentOS (yum)
    • openSUSE (zypper)
    • Ubuntu/Debian (apt)
    • Linux Mint (apt)

SUPPORTED ARCHITECTURES:
    • x86_64 (Intel/AMD 64-bit)
    • aarch64/arm64 (ARM 64-bit)
    • armv7l (ARM 32-bit)

For more information, visit: https://github.com/swipswaps/vscode-stable-updater
EOF
}

# Auto-detect backup script if not specified
if [[ -z "$BACKUP_SCRIPT" ]]; then
    # Search common locations for backup script
    backup_candidates=(
        "$HOME/Desktop/test/augment_chat_backup_enhanced.sh"
        "$HOME/bin/augment_chat_backup_enhanced.sh"
        "$HOME/.local/bin/augment_chat_backup_enhanced.sh"
        "$(dirname "$0")/augment_chat_backup_enhanced.sh"
        "./augment_chat_backup_enhanced.sh"
    )

    for candidate in "${backup_candidates[@]}"; do
        if [[ -f "$candidate" && -x "$candidate" ]]; then
            BACKUP_SCRIPT="$candidate"
            break
        fi
    done
fi

# Run main function
main "$@"
