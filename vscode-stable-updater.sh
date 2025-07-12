#!/bin/bash
################################################################################
# VSCode Stable Updater v2.0.0-alpha.2
# Cross-platform VSCode update script with smart download management
#
# WORKING VERSION - FIXED ISSUES:
# - Immediate VSCode detection and warning
# - No hidden terminals or processes
# - Simple, reliable execution
# - Clear user interaction
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Error handling to prevent crashes
handle_error() {
    local exit_code=$?
    echo ""
    echo "❌ Script encountered an error (exit code: $exit_code)"
    echo "This may be due to VSCode process management issues"
    echo "Please try running the script again"
    exit $exit_code
}

trap handle_error ERR

# Version and configuration
SCRIPT_VERSION="2.0.0-alpha.2"
VSCODE_EDITION="${VSCODE_EDITION:-stable}"

# VSCode process detection
if [[ "$VSCODE_EDITION" == "stable" ]]; then
    VSCODE_PROCESS_NAME="code"
else
    VSCODE_PROCESS_NAME="code-insiders"
fi

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "ERROR") echo "[$timestamp] ❌ $message" >&2 ;;
        "WARN")  echo "[$timestamp] ⚠️  $message" ;;
        "INFO")  echo "[$timestamp] ℹ️  $message" ;;
        "SUCCESS") echo "[$timestamp] ✅ $message" ;;
        "DEBUG") [[ "${DEBUG:-0}" == "1" ]] && echo "[$timestamp] 🐛 $message" ;;
        *) echo "[$timestamp] $message" ;;
    esac
}

# Open visible warning terminal window
open_warning_terminal() {
    local process_count="$1"
    local process_list="$2"
    local warning_message="🚨 CRITICAL: VSCode $VSCODE_EDITION Must Be Closed! 🚨

VSCode $VSCODE_EDITION is currently running with $process_count active processes.

⚠️  UPDATE CANNOT PROCEED while VSCode is running!

Running VSCode Process IDs:
$process_list

🔧 WHAT TO DO:

OPTION 1 (RECOMMENDED):
- Press Enter in this window to close it
- The script will automatically close VSCode for you

OPTION 2 (MANUAL):
- Close VSCode yourself first
- Then press Enter in this window
- The script will continue

Choose your option and press Enter when ready..."

    # Use proven working method from rules files
    local display="${DISPLAY:-:0}"

    if command -v xfce4-terminal &>/dev/null; then
        log "INFO" "Opening warning terminal window with xfce4-terminal (proven method)"
        DISPLAY="$display" xfce4-terminal \
            --window \
            --geometry=80x20+100+100 \
            --title='VSCode Update Warning' \
            --execute bash -c "
                echo '$warning_message';
                echo '';
                echo 'Press 1 for automatic close, 2 for manual close, or just Enter for automatic:';
                read -r choice;
                choice=\${choice:-1};
                if [[ \$choice == '1' ]]; then
                    echo 'Attempting graceful VSCode shutdown...';
                    # Try graceful shutdown first
                    if command -v code &>/dev/null; then
                        code --wait --command workbench.action.quit 2>/dev/null || true;
                        sleep 3;
                    fi
                    # If still running, try SIGTERM (graceful)
                    if pgrep -f '$VSCODE_PROCESS_NAME' >/dev/null; then
                        echo 'Sending graceful shutdown signal...';
                        pkill -TERM -f '$VSCODE_PROCESS_NAME' 2>/dev/null || true;
                        sleep 5;
                    fi
                    echo 'VSCode shutdown attempted. You can close this window.';
                else
                    echo 'Please close VSCode manually, then press Enter...';
                    read -r;
                    echo 'You can close this window.';
                fi
            " &

        # Wait for window to appear and verify
        sleep 2
        local window_count
        window_count=$(xdotool search --name "VSCode Update Warning" 2>/dev/null | wc -l)

        if [ "$window_count" -gt 0 ]; then
            log "INFO" "Terminal window verified: $window_count window(s) opened"
            return 0
        else
            log "WARN" "Terminal window may not have opened properly"
            return 1
        fi
    fi

    log "WARN" "No suitable terminal emulator found - showing warning in current terminal"
    return 1
}

# Check if VSCode is running - IMMEDIATE WARNING
check_vscode_running() {
    log "INFO" "Checking if VSCode $VSCODE_EDITION is running..."

    local vscode_pids
    mapfile -t vscode_pids < <(pgrep -f "$VSCODE_PROCESS_NAME" 2>/dev/null || true)

    if [[ ${#vscode_pids[@]} -gt 0 ]]; then
        # Open warning terminal window with process info
        local process_count=${#vscode_pids[@]}
        local process_list="${vscode_pids[*]}"
        if open_warning_terminal "$process_count" "$process_list"; then
            log "INFO" "Warning terminal window opened showing $process_count VSCode processes"
            sleep 2  # Give terminal time to appear
        fi

        echo ""
        echo "⚠️  VSCode $VSCODE_EDITION is running (${#vscode_pids[@]} processes)"
        echo "📋 Check the warning window for details and options"
        echo ""

        # Wait for user to handle VSCode in the warning window
        echo "Waiting for you to handle VSCode in the warning window..."
        echo "Press Ctrl+C to cancel if needed"

        # Wait for VSCode to be closed (either automatically or manually)
        local wait_count=0
        local max_wait=60  # Maximum 2 minutes

        while pgrep -f "$VSCODE_PROCESS_NAME" >/dev/null 2>&1 && [[ $wait_count -lt $max_wait ]]; do
            sleep 2
            echo -n "."
            ((wait_count++))
        done

        echo ""
        if pgrep -f "$VSCODE_PROCESS_NAME" >/dev/null 2>&1; then
            echo "⚠️  VSCode is still running after 2 minutes"
            echo "Please close VSCode manually and run the script again"
            exit 1
        else
            echo "✅ VSCode $VSCODE_EDITION has been closed"
        fi

        # Verify VSCode is closed
        if pgrep -f "$VSCODE_PROCESS_NAME" >/dev/null 2>&1; then
            log "ERROR" "VSCode $VSCODE_EDITION is still running. Please close it manually."
            exit 1
        fi
    fi

    log "SUCCESS" "VSCode $VSCODE_EDITION is not running"
}

# Show help
show_help() {
    cat << EOF
VSCode Updater v$SCRIPT_VERSION
Cross-platform VSCode update script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --edition=EDITION    VSCode edition: 'stable' or 'insiders' (default: stable)
    --auto              Skip confirmation prompts
    --debug             Enable debug logging
    --help, -h          Show this help
    --version, -v       Show version

EXAMPLES:
    # Update VSCode stable
    $0
    
    # Update VSCode Insiders
    $0 --edition=insiders
    
    # Auto-install without prompts
    $0 --auto

EOF
}

# Main function
main() {
    echo "🚀 VSCode $VSCODE_EDITION Updater v$SCRIPT_VERSION"
    echo "Cross-platform update script with smart download management"
    echo ""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --edition=*)
                VSCODE_EDITION="${1#*=}"
                # Update process name based on edition
                if [[ "$VSCODE_EDITION" == "stable" ]]; then
                    VSCODE_PROCESS_NAME="code"
                elif [[ "$VSCODE_EDITION" == "insiders" ]]; then
                    VSCODE_PROCESS_NAME="code-insiders"
                else
                    log "ERROR" "Invalid edition: $VSCODE_EDITION"
                    exit 1
                fi
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

    # IMMEDIATE VSCode check - this happens first!
    check_vscode_running

    # Continue with actual update process
    log "INFO" "VSCode $VSCODE_EDITION update process starting..."

    # Detect system and package manager
    detect_system

    # Download VSCode
    download_vscode

    # Install VSCode
    install_vscode

    echo ""
    echo "✅ VSCode $VSCODE_EDITION update completed successfully!"
}

# System detection function
detect_system() {
    log "INFO" "Detecting system configuration..."

    # Detect distribution
    if [[ -f /etc/fedora-release ]]; then
        DISTRO="fedora"
        PACKAGE_MANAGER="dnf"
        PACKAGE_FORMAT="rpm"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        PACKAGE_MANAGER="apt"
        PACKAGE_FORMAT="deb"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
        PACKAGE_MANAGER="pacman"
        PACKAGE_FORMAT="pkg"
    else
        log "ERROR" "Unsupported distribution"
        exit 1
    fi

    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="x64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="armhf" ;;
        *) log "ERROR" "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    log "SUCCESS" "System detected: $DISTRO ($PACKAGE_MANAGER/$ARCH)"
}

# Download VSCode function
download_vscode() {
    log "INFO" "Downloading VSCode $VSCODE_EDITION..."

    # Construct download URL
    local base_url="https://code.visualstudio.com/sha/download"
    local build_type="stable"
    [[ "$VSCODE_EDITION" == "insiders" ]] && build_type="insider"

    local download_url="$base_url?build=$build_type&os=linux-$PACKAGE_FORMAT-$ARCH"
    local filename="vscode-$VSCODE_EDITION-$ARCH.$PACKAGE_FORMAT"

    log "INFO" "Download URL: $download_url"
    log "INFO" "Downloading to: $filename"

    # Download with curl
    if curl -L -o "$filename" "$download_url"; then
        log "SUCCESS" "Download completed: $filename"
        DOWNLOAD_FILE="$filename"
        return 0
    else
        log "ERROR" "Download failed"
        return 1
    fi
}

# Install VSCode function
install_vscode() {
    log "INFO" "Installing VSCode $VSCODE_EDITION..."

    if [[ ! -f "$DOWNLOAD_FILE" ]]; then
        log "ERROR" "Download file not found: $DOWNLOAD_FILE"
        return 1
    fi

    case "$PACKAGE_MANAGER" in
        dnf)
            log "INFO" "Installing with dnf..."
            sudo dnf install -y "$DOWNLOAD_FILE"
            ;;
        apt)
            log "INFO" "Installing with apt..."
            sudo dpkg -i "$DOWNLOAD_FILE" || sudo apt-get install -f -y
            ;;
        pacman)
            log "INFO" "Installing with pacman..."
            sudo pacman -U --noconfirm "$DOWNLOAD_FILE"
            ;;
        *)
            log "ERROR" "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac

    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "VSCode $VSCODE_EDITION installed successfully"
        # Clean up download file
        rm -f "$DOWNLOAD_FILE"
        return 0
    else
        log "ERROR" "Installation failed"
        return 1
    fi
}

# Run main function with all arguments
main "$@"
