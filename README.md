# VM Server Agent

A lightweight agent for VM monitoring and management.

## Quick Installation

Install with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/devops-vm-agent/main/install.sh | bash
```

This installer script will:
- Auto-detect your OS and architecture
- Download the latest binary
- Verify checksums
- Install to `/usr/local/bin/vm-server-agent`
- Create config directory at `/etc/vm-server-agent`

## Supported Platforms

- **Linux**: amd64, arm64
- **macOS**: Intel (amd64), Apple Silicon (arm64)

## Manual Installation

If you prefer to install manually:

### Linux (amd64)
```bash
# Download the latest release
curl -LO https://github.com/devops-vm-agent/releases/latest/download/vm-server-agent-linux-amd64.tar.gz

# Extract
tar -xzf vm-server-agent-linux-amd64.tar.gz

# Install
sudo mv vm-server-agent-linux-amd64 /usr/local/bin/vm-server-agent
sudo chmod +x /usr/local/bin/vm-server-agent

# Verify
vm-server-agent --version
```

### Linux (arm64)
```bash
curl -LO https://github.com/devops-vm-agent/releases/latest/download/vm-server-agent-linux-arm64.tar.gz
tar -xzf vm-server-agent-linux-arm64.tar.gz
sudo mv vm-server-agent-linux-arm64 /usr/local/bin/vm-server-agent
sudo chmod +x /usr/local/bin/vm-server-agent
vm-server-agent --version
```

### macOS (Intel)
```bash
curl -LO https://github.com/devops-vm-agent/releases/latest/download/vm-server-agent-darwin-amd64.tar.gz
tar -xzf vm-server-agent-darwin-amd64.tar.gz
sudo mv vm-server-agent-darwin-amd64 /usr/local/bin/vm-server-agent
sudo chmod +x /usr/local/bin/vm-server-agent
vm-server-agent --version
```

### macOS (Apple Silicon)
```bash
curl -LO https://github.com/devops-vm-agent/releases/latest/download/vm-server-agent-darwin-arm64.tar.gz
tar -xzf vm-server-agent-darwin-arm64.tar.gz
sudo mv vm-server-agent-darwin-arm64 /usr/local/bin/vm-server-agent
sudo chmod +x /usr/local/bin/vm-server-agent
vm-server-agent --version
```

## Checksum Verification

For enhanced security, verify the downloaded binary:

```bash
# Download checksums
curl -LO https://github.com/devops-vm-agent/releases/latest/download/SHA256SUMS

# Verify (Linux)
sha256sum -c SHA256SUMS 2>&1 | grep vm-server-agent

# Verify (macOS)
shasum -a 256 -c SHA256SUMS 2>&1 | grep vm-server-agent
```

## Configuration

After installation, create a configuration file:

```bash
sudo mkdir -p /etc/vm-server-agent
sudo nano /etc/vm-server-agent/config.yaml
```

Example configuration:

```yaml
server:
  url: "https://your-server.com"
  token: "your-auth-token"

agent:
  hostname: "my-vm"
  check_interval: 30s
```

## Running the Agent

### Foreground (for testing)
```bash
vm-server-agent --config /etc/vm-server-agent/config.yaml
```

### As a Systemd Service (recommended for production)

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/vm-server-agent.service
```

Add the following content:

```ini
[Unit]
Description=VM Server Agent
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/vm-server-agent --config /etc/vm-server-agent/config.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable vm-server-agent
sudo systemctl start vm-server-agent

# Check status
sudo systemctl status vm-server-agent

# View logs
sudo journalctl -u vm-server-agent -f
```

## Updating

To update to the latest version, simply run the installer script again:

```bash
curl -sSL https://raw.githubusercontent.com/devops-vm-agent/main/install.sh | bash
```

Or manually download the new binary and replace the existing one.

## Uninstalling

```bash
# Stop the service (if running as systemd)
sudo systemctl stop vm-server-agent
sudo systemctl disable vm-server-agent
sudo rm /etc/systemd/system/vm-server-agent.service

# Remove binary
sudo rm /usr/local/bin/vm-server-agent

# Remove config (optional)
sudo rm -rf /etc/vm-server-agent
```

## Releases

See the [Releases page](https://github.com/devops-vm-agent/releases) for all available versions and release notes.

## Support

For issues, questions, or contributions, please contact your system administrator or check the internal documentation.

---

**Note**: This repository contains only release artifacts (binaries and installers). The source code is maintained in a private repository.
