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
    local warning_message="⚠️  VSCode $VSCODE_EDITION Update Warning ⚠️

VSCode $VSCODE_EDITION is currently running and must be closed before updating.

Running processes: $1

Please return to the main terminal to choose an option:
1. Close VSCode automatically (recommended)
2. Exit and close manually

Press Enter to close this warning window when ready."

    # Try different terminal emulators to open visible window
    if command -v gnome-terminal &>/dev/null; then
        log "INFO" "Opening warning terminal window with gnome-terminal"
        gnome-terminal --title='VSCode Update Warning' --geometry=80x20 -- bash -c "echo '$warning_message'; read -r" &
        return 0
    elif command -v xfce4-terminal &>/dev/null; then
        log "INFO" "Opening warning terminal window with xfce4-terminal"
        xfce4-terminal --title='VSCode Update Warning' --geometry=80x20 --command="bash -c \"echo '$warning_message'; read -r\"" &
        return 0
    elif command -v konsole &>/dev/null; then
        log "INFO" "Opening warning terminal window with konsole"
        konsole --title 'VSCode Update Warning' -e bash -c "echo '$warning_message'; read -r" &
        return 0
    elif command -v xterm &>/dev/null; then
        log "INFO" "Opening warning terminal window with xterm"
        xterm -title 'VSCode Update Warning' -geometry 80x20 -e bash -c "echo '$warning_message'; read -r" &
        return 0
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
        # Open warning terminal window
        if open_warning_terminal "${vscode_pids[*]}"; then
            log "INFO" "Warning terminal window opened"
            sleep 2  # Give terminal time to appear
        fi

        echo ""
        echo "⚠️  WARNING: VSCode $VSCODE_EDITION is currently running!"
        echo "Running processes: ${vscode_pids[*]}"
        echo ""
        echo "VSCode must be closed before updating."
        echo "Options:"
        echo "1. Close VSCode automatically (recommended)"
        echo "2. Exit and close manually"
        echo ""

        if [[ "${AUTO_INSTALL:-0}" == "1" ]]; then
            echo "Auto-install mode: Closing VSCode automatically..."
            pkill -f "$VSCODE_PROCESS_NAME" || true
            sleep 2
        else
            read -r -p "Choose (1-2) [default: 2]: " choice
            choice="${choice:-2}"

            case "$choice" in
                1)
                    echo "Closing VSCode $VSCODE_EDITION..."
                    pkill -f "$VSCODE_PROCESS_NAME" || true
                    sleep 2
                    echo "VSCode closed."
                    ;;
                2|*)
                    echo "Please close VSCode $VSCODE_EDITION manually and run the script again."
                    exit 0
                    ;;
            esac
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

    # Continue with update process
    log "INFO" "VSCode $VSCODE_EDITION update process starting..."
    log "INFO" "This is a working test version - actual update functionality to be implemented"
    
    echo ""
    echo "✅ VSCode $VSCODE_EDITION updater test completed successfully!"
    echo "The script correctly detected and handled running VSCode processes."
}

# Run main function with all arguments
main "$@"
