# MikroTik Port Knocking: Client Script for Stealth Access

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/shell-bash-lightgreen.svg)

An optimized Bash client script for reliable **Port Knocking** on your MikroTik router. Designed for Android (Termux), Linux, and macOS, it ensures successful **MikroTik Port Knocking** even on unstable networks.

## Table of Contents
*   [Why This Script?](#why-this-script)
*   [Features](#features)
*   [Prerequisites](#prerequisites)
*   [Installation](#installation)
*   [Usage](#usage)
*   [Configuration](#configuration)
*   [How It Works](#how-it-works)
*   [Troubleshooting](#troubleshooting)
*   [Related Article](#related-article)
*   [License](#license)

## Why This Script?

This script enhances **MikroTik Port Knocking** reliability by automatically choosing the best connection method (`netcat`, `telnet`, `curl`, or Bash TCP) and including built-in retry logic. It's built for resilience and ease of use on various client systems, making your remote MikroTik access more robust.

## Features

*   **Multi-Method Port Knocking:** Adapts to available tools (nc, telnet, curl, bash TCP).
*   **Retry Logic & Timeouts:** Configurable retries and connection timeouts for reliability.
*   **Clear Feedback:** Color-coded messages for real-time status.
*   **Cross-Platform:** Compatible with Android (Termux) and Linux/macOS.
*   **Argument-Based IP:** Pass MikroTik IP/hostname directly.
*   **Pre-Flight Checks:** Verifies tools and basic connectivity.

## Prerequisites

Requires a MikroTik router with **Port Knocking** configured. On your client (Linux/Termux), ensure you have:
*   `ping`
*   `timeout` (from `termux-tools` or `coreutils`)
*   At least one of: `nc` (from `nmap-ncat`), `telnet`, or `curl`.

**Termux Installation:**
```bash
pkg update && pkg upgrade
pkg install termux-tools nmap-ncat # Essential tools
# Optional: pkg install telnet curl
```

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-github-username/mikrotik-port-knocking-client.git
    cd mikrotik-port-knocking-client
    ```
2.  **Or, download directly:**
    ```bash
    wget https://raw.githubusercontent.com/your-github-username/mikrotik-port-knocking-client/main/portknock.sh
    ```
3.  **Make executable:**
    ```bash
    chmod +x portknock.sh
    ```

## Usage

Run the script with your MikroTik router's IP or hostname:

```bash
./portknock.sh <YOUR_MIKROTIK_IP_OR_HOSTNAME>
```

**Example:**
```bash
./portknock.sh 192.168.1.1
```

## Configuration

Adjust these variables within the `portknock.sh` script to match your **MikroTik Port Knocking** setup:

```bash
# Configuration
ROUTER_IP="$1"            # Passed as first argument
KNOCK_PORTS=(1001 2002 3003) # Must match your MikroTik firewall
KNOCK_DELAY=3             # Pause between knocks (seconds)
CONNECTION_TIMEOUT=2      # Timeout per connection attempt (seconds)
RETRY_COUNT=3             # Number of retries per port
```

## How It Works

This script performs **MikroTik Port Knocking** by:
1.  **Detecting tools:** Automatically finds the most reliable TCP connection method.
2.  **Sequential Knocking:** Attempts connections to each port in your `KNOCK_PORTS` array.
3.  **Retrying:** If a knock fails, it retries up to `RETRY_COUNT` times.
4.  **Delaying:** Pauses for `KNOCK_DELAY` between each successful knock.
5.  **Verifying:** After knocking, it tests common MikroTik service ports to confirm access.

## Troubleshooting

For detailed troubleshooting steps regarding your **MikroTik Port Knocking** setup, including firewall rule order and timeout issues, please refer to our comprehensive article:

➡️ **[Port Knocking MikroTik: Stealth Access & Email Alerts!](https://www.sec-ttl.com/mikrotik-port-knocking-unlock-like-a-stealth-pro/#troubleshooting)**

## Related Article

Find the full guide on setting up **MikroTik Port Knocking** on your router, including firewall rules and email alerts:

➡️ **[Port Knocking MikroTik: Stealth Access & Email Alerts!](https://www.sec-ttl.com/mikrotik-port-knocking-unlock-like-a-stealth-pro/)**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
