#!/bin/bash
set -e

# VM Server Agent Installer Script
# This script auto-detects your OS and architecture, downloads the latest binary,
# verifies the checksum, and installs it to your system.

APP_NAME="vm-server-agent"
GITHUB_REPO="uditk2/devops-vm-agent"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/vm-server-agent"

# OTP passed as first argument, server URL as second
OTP="${1:-}"
SERVER_URL="${2:-http://localhost:3000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$OS" in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    PLATFORM="${OS}-${ARCH}"
    print_info "Detected platform: $PLATFORM"
}

# Get latest release version from GitHub
get_latest_version() {
    print_info "Fetching latest release version..."

    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")
    VERSION=$(echo "$LATEST_RELEASE" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": "\(.*\)"/\1/')

    if [ -z "$VERSION" ]; then
        print_error "Failed to fetch latest version"
        exit 1
    fi

    print_info "Latest version: $VERSION"
}

# Download binary and checksums
download_files() {
    BINARY_NAME="${APP_NAME}-${PLATFORM}"
    TARBALL_NAME="${BINARY_NAME}.tar.gz"
    DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/${TARBALL_NAME}"
    CHECKSUM_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/SHA256SUMS"

    print_info "Downloading ${TARBALL_NAME}..."

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    if ! curl -fsSL -o "$TARBALL_NAME" "$DOWNLOAD_URL"; then
        print_error "Failed to download binary from $DOWNLOAD_URL"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    print_info "Downloading checksums..."
    if ! curl -fsSL -o "SHA256SUMS" "$CHECKSUM_URL"; then
        print_error "Failed to download checksums"
        rm -rf "$TMP_DIR"
        exit 1
    fi
}

# Verify checksum
verify_checksum() {
    print_info "Verifying checksum..."

    # Extract the checksum for our specific file
    EXPECTED_CHECKSUM=$(grep "$TARBALL_NAME" SHA256SUMS | awk '{print $1}')

    if [ -z "$EXPECTED_CHECKSUM" ]; then
        print_error "Checksum not found for $TARBALL_NAME"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Calculate actual checksum
    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL_CHECKSUM=$(sha256sum "$TARBALL_NAME" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        ACTUAL_CHECKSUM=$(shasum -a 256 "$TARBALL_NAME" | awk '{print $1}')
    else
        print_warn "sha256sum not found, skipping checksum verification"
        return
    fi

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        print_error "Checksum verification failed!"
        print_error "Expected: $EXPECTED_CHECKSUM"
        print_error "Got: $ACTUAL_CHECKSUM"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    print_info "Checksum verified successfully!"
}

# Extract and install
install_binary() {
    print_info "Extracting binary..."
    tar -xzf "$TARBALL_NAME"

    if [ ! -f "$BINARY_NAME" ]; then
        print_error "Binary not found after extraction"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    print_info "Installing to ${INSTALL_DIR}/${APP_NAME}..."

    # Check if we need sudo
    if [ -w "$INSTALL_DIR" ]; then
        mv "$BINARY_NAME" "${INSTALL_DIR}/${APP_NAME}"
        chmod +x "${INSTALL_DIR}/${APP_NAME}"
    else
        sudo mv "$BINARY_NAME" "${INSTALL_DIR}/${APP_NAME}"
        sudo chmod +x "${INSTALL_DIR}/${APP_NAME}"
    fi

    # Create config directory
    if [ ! -d "$CONFIG_DIR" ]; then
        print_info "Creating config directory at $CONFIG_DIR..."
        if [ -w "$(dirname "$CONFIG_DIR")" ]; then
            mkdir -p "$CONFIG_DIR"
        else
            sudo mkdir -p "$CONFIG_DIR"
        fi
    fi

    # Cleanup
    cd -
    rm -rf "$TMP_DIR"
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."

    if ! command -v "$APP_NAME" >/dev/null 2>&1; then
        print_error "Installation failed: $APP_NAME not found in PATH"
        exit 1
    fi

    INSTALLED_VERSION=$("$APP_NAME" --version 2>/dev/null || echo "unknown")
    print_info "Installed version: $INSTALLED_VERSION"
}

# Main installation flow
main() {
    echo ""
    print_info "VM Server Agent Installer"
    print_info "=========================================="
    echo ""

    detect_platform
    get_latest_version
    download_files
    verify_checksum
    install_binary
    verify_installation

    echo ""
    print_info "=========================================="
    print_info "Installation complete! 🎉"
    echo ""

    if [ -n "$OTP" ]; then
        print_info "Registering agent with OTP: $OTP"
        print_info "Server URL: $SERVER_URL"
        print_info "Starting agent registration process..."
        # Register the agent with the central server (needs permission to write /etc/vm-server-agent/config.yaml)
        if command -v sudo >/dev/null 2>&1; then
            sudo "$APP_NAME" --register --otp "$OTP" --server "$SERVER_URL"
        else
            "$APP_NAME" --register --otp "$OTP" --server "$SERVER_URL"
        fi

        print_info "Starting agent..."
        # Start the agent in the background
        if command -v nohup >/dev/null 2>&1; then
            LOG_FILE="/var/log/vm-server-agent.log"
            if command -v sudo >/dev/null 2>&1; then
                sudo sh -c "nohup $APP_NAME --config ${CONFIG_DIR}/config.yaml > $LOG_FILE 2>&1 &"
            else
                nohup "$APP_NAME" --config "${CONFIG_DIR}/config.yaml" > "$LOG_FILE" 2>&1 &
            fi
            print_info "Agent started successfully! Logs: $LOG_FILE"
        else
            print_warn "nohup not found. Please start the agent manually:"
            echo "  sudo $APP_NAME --config ${CONFIG_DIR}/config.yaml"
        fi
    else
        print_warn "No OTP provided. Skipping automatic registration."
        print_info "Next steps:"
        echo "  1. Create a config file: sudo nano ${CONFIG_DIR}/config.yaml"
        echo "  2. Run the agent: $APP_NAME"
        echo "  3. View help: $APP_NAME --help"
    fi

    echo ""
}

# Run main function
main
