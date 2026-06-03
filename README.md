# sniky-cho

> Silent network reconnaissance TUI — passive + semi-passive, leaves no trace.

A terminal-based network recon tool written in Bash. Designed for passive information gathering on your own local network. Most modules send **zero packets** — your machine listens, it does not talk.

![bash](https://img.shields.io/badge/bash-5.x-informational?style=flat&color=7c3aed)
![platform](https://img.shields.io/badge/platform-linux-informational?style=flat&color=7c3aed)
![license](https://img.shields.io/badge/license-MIT-informational?style=flat&color=7c3aed)

---

## Features

| Module | Type | Description |
|---|---|---|
| network info | passive | IP, gateway, WiFi signal and DNS servers |
| arp table | passive | Known hosts — zero packets sent |
| passive capture | passive | MACs and IPs circulating on the network via tcpdump |
| mdns / bonjour | passive | Self-announcing devices (printers, IoT, smart TVs) |
| oui lookup | passive | Identify device manufacturer by MAC address |
| wifi scan | passive | Nearby networks with channel, signal and security type |
| nmap gateway | semi-passive | Open ports on the router |
| banner grab | semi-passive | Router firmware version via TCP banner |
| snmp | semi-passive | Internal router info if SNMP is enabled |
| reverse dns | semi-passive | PTR record of the gateway |

---

## Alfa adapter — extended range and monitor mode

An external USB WiFi adapter compatible with monitor mode (e.g. **Alfa AWUS036ACH**, MT7610U, RTL8812AU) unlocks two key capabilities:

- **Monitor mode** — raw 802.11 frame capture from *all* nearby devices, not just those on your network. See every MAC in the air.
- **Extended range** — Alfa antennas reach significantly further than built-in adapters, picking up more distant networks and devices.

Without one, all passive managed-mode features work normally.

---

## Requirements

```
iw · ip · nmcli          # interface management (usually pre-installed)
tcpdump                   # passive capture (module 3)
nmap                      # gateway scan (module 7) + OUI database
avahi                     # mDNS discovery (module 4)
net-snmp                  # SNMP queries (module 9)
dig                       # reverse DNS (module 0)
```

OUI vendor lookup uses the nmap MAC prefix database at `/usr/share/nmap/nmap-mac-prefixes`.

Install on Arch Linux:
```bash
sudo pacman -S tcpdump nmap avahi net-snmp bind
```

---

## Usage

```bash
git clone https://github.com/YoshiBigSmoke/sniky-cho.git
cd sniky-cho
chmod +x sniky-cho.sh

./sniky-cho.sh          # passive modules work without root
sudo ./sniky-cho.sh     # full access: monitor mode + tcpdump
```

The tool auto-detects your active interface on startup. All options include a short description — no prior knowledge needed to navigate.

---

## How it works

Single self-contained Bash script. No install step, no dependencies beyond standard Linux tools.

```
passive modules    → read-only: ARP cache, iw, nmcli, resolvectl
capture modules    → tcpdump in listen-only mode, no packet injection
semi-passive       → controlled probes: nmap, TCP banner grab, SNMP, dig
monitor mode       → raw 802.11 via iw, NetworkManager temporarily paused
```

---

## Legal

For use on networks you own or have explicit written permission to test.  
Passive listening on your own network is generally legal; verify local regulations before use on any shared or public network.
