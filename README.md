# TOrchik v1.0 (Stable Edition)

## Overview

TOrchik is a CLI-based automation tool for configuring and managing a Tor + Proxychains environment on Linux systems.

The interface is styled in a TRON: Legacy / neon grid aesthetic and focuses on minimalism, clarity, and control.

---

## Features

### Full Setup & Initialization

- Installs required dependencies:
    
    - tor
        
    - proxychains4
        
    - curl
        
    - obfs4proxy
        
    - webtunnel
        
    - xterm
        
- Fetches fresh Tor bridges
    
- Configures /etc/tor/torrc
    
- Configures /etc/proxychains4.conf
    
- Restarts Tor service
    
- Waits for full Tor bootstrap (100%)
    
- Opens live Tor logs in a separate terminal window
    

---

### Change IP (New Identity)

- Restarts Tor service
    
- Waits for reconnection
    
- Displays new Tor IP
    

---

### IP Check

- Shows:
    
    - Real IP
        
    - Tor IP (via proxychains)
        

---

### Backup & Restore

- Creates backups of:
    
    - torrc
        
    - proxychains4.conf
        
- Allows restoring original configs
    

---

### Bridge Fetching

- Pulls bridges from:  
    [https://www.triplebit.org/bridges/](https://www.triplebit.org/bridges/)
    

Supports:

- obfs4 bridges
    
- webtunnel bridges
    

---

### Logging System

Logs all actions to:

```
TOrchik.log
```

Includes timestamps for tracking and debugging

---

### Proxychains Manual

Built-in reference with examples:

- Browser via Tor
    
- Nmap scanning
    

Includes note on Tor limitations (no UDP/ICMP)

---

### Multi-language Support

- English
    
- Russian
    

Language is selected on first launch and stored in:

```
torchik.conf
```

---

## Requirements

- Linux (Debian/Ubuntu recommended)
    
- Root privileges (sudo)
    
- Internet connection
    

---

## Installation

### 1. Clone or download

```
git clone https://github.com/kevinflyn1970-a11y/TOrchik
cd TOrchik
```

---

### 2. Make executable

```
chmod +x TOrchik_1.0.sh
```

---

### 3. Run

```
sudo ./TOrchik_1.0.sh
```

---

## Usage

Interactive menu:

```
1. INITIALIZE  - Full setup & start
2. NEW ID      - Change IP
3. CHECK       - Check IP
4. RESTORE     - Restore configs
5. MANUAL      - Proxychains reference
6. EXIT
```

---

## How It Works

1. Installs dependencies via APT
    
2. Fetches Tor bridges
    
3. Rewrites Tor configuration
    
4. Configures Proxychains (SOCKS5)
    
5. Restarts Tor
    
6. Monitors bootstrap via journalctl
    
7. Routes traffic through Tor
    

---

## Notes & Limitations

- Tor does not support UDP or ICMP  
    (ping will not work)
    
- Some services block Tor exit nodes
    
- Requires root access
    

---

## Project Structure

```
TOrchik_1.0.sh   - main script
TOrchik.log      - log file
torchik.conf     - language config

torrc.bak
proxychains4.bak
```

---

## Troubleshooting

Tor status:

```
systemctl status tor
journalctl -u tor@default
```

Proxychains config:

```
cat /etc/proxychains4.conf
```

---

## Disclaimer

Intended for:

- Privacy
    
- Education
    
- Security research
    

Do not use for illegal activities.

---

## Future Improvements

- GUI version
    
- Auto IP rotation
    
- SOCKS5 API mode
    
- Docker support
    
- Multi-hop chains
    

---

## Author

TOrchik v1.0  
TRON-inspired Tor automation tool
