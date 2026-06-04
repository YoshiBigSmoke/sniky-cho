#!/bin/bash
# demo.sh — Simulates sniky-cho UI for recording (no real network calls, no real IPs)

PU='\033[1;35m'
PM='\033[0;35m'
GR='\033[0;32m'
YE='\033[0;33m'
RE='\033[0;31m'
WH='\033[1;37m'
DI='\033[2;37m'
CY='\033[0;36m'
N='\033[0m'

line()  { echo -e "${DI}  ────────────────────────────────────────────────────────${N}"; }
ok()    { echo -e "  ${GR}✓${N}  $*"; }
info()  { echo -e "  ${PM}·${N}  $*"; }
tip()   { echo -e "  ${CY}→${N}  $*"; }
row()   { echo -e "     $*"; }

type_out() {
  local text="$1" delay="${2:-0.08}"
  for (( i=0; i<${#text}; i++ )); do
    printf "%s" "${text:$i:1}"; sleep "$delay"
  done
  echo ""
}

menu() {
  clear; echo ""
  echo -ne "  ${PU}◈ sniky-cho${N}  ${DI}·${N}  ${WH}wlan0${N}  ${DI}·${N}  ${WH}192.168.4.12/24${N}  ${DI}·${N}  gw ${WH}192.168.4.1${N}  ${DI}·${N}  ${PM}HomeNetwork_5G${N}  ${DI}·${N}  ${GR}-61 dBm${N}"
  echo ""; echo ""; line; echo ""
  echo -e "  ${PM}passive${N}"
  echo -e "  ${WH}1${N}   network info         ${DI}ip, gateway, wifi signal and dns${N}"
  echo -e "  ${WH}2${N}   arp table            ${DI}known hosts with zero packets sent${N}"
  echo -e "  ${WH}3${N}   passive capture      ${DI}macs and ips circulating on the network${N}"
  echo -e "  ${WH}4${N}   mdns / bonjour        ${DI}devices that announce themselves${N}"
  echo -e "  ${WH}5${N}   oui lookup            ${DI}identify any device by mac address${N}"
  echo -e "  ${WH}6${N}   wifi scan             ${DI}nearby networks, channel and security type${N}"
  echo ""
  echo -e "  ${PM}semi-passive${N}"
  echo -e "  ${WH}7${N}   nmap gateway          ${DI}open ports on the router${N}"
  echo -e "  ${WH}8${N}   banner grab           ${DI}exact firmware version of the router${N}"
  echo -e "  ${WH}9${N}   snmp                  ${DI}internal router info if allowed${N}"
  echo -e "  ${WH}0${N}   reverse dns           ${DI}domain name of the gateway${N}"
  echo ""
  echo -e "  ${PM}config${N}"
  echo -e "  ${WH}i${N}   interface             ${DI}change active network adapter${N}"
  echo -e "  ${WH}m${N}   monitor on/off        ${DI}capture raw wifi frames from the air${N}"
  echo -e "  ${WH}q${N}   quit"
  echo ""
  echo -ne "  ${PU}›${N} "
}

# ── Banner ────────────────────────────────────────────────────────────────────
clear; echo ""
echo -e "  ${PU}◈  sniky-cho${N}"
echo -e "  ${DI}────────────────────────────────────────────────────────${N}"
echo -e "  ${DI}silent network reconnaissance tool${N}"
echo -e "  ${DI}passive + semi-passive · leaves no trace on the network${N}"
echo ""
echo -e "  ${DI}────────────────────────────────────────────────────────${N}"
echo -e "  ${CY}→${N}  ${WH}Alfa adapter${N}  ${DI}(AWUS036ACH / MT7610U / RTL8812AU)${N}"
echo -e "  ${DI}   Plug one in to unlock monitor mode and capture raw${N}"
echo -e "  ${DI}   802.11 frames from ${WH}all${DI} nearby devices — not just${N}"
echo -e "  ${DI}   those on your network. Extended range included.${N}"
echo -e "  ${DI}   Without it, passive managed-mode features still work.${N}"
echo -e "  ${DI}────────────────────────────────────────────────────────${N}"
echo ""
sleep 0.6
ok "Auto-detected interface: ${WH}wlan0${N}  ${DI}(change with option i if needed)${N}"
echo ""
echo -ne "  ${DI}↵ continue${N} "; sleep 1.8; echo ""

# ── Menu → 1 (network info) ───────────────────────────────────────────────────
menu; sleep 1.0; type_out "1" 0.1

clear; echo ""
echo -e "  ${PU}◈ sniky-cho${N}  ${DI}›${N}  ${WH}network info${N}"
echo -e "  ${DI}  fully passive · sends zero packets${N}"
line; echo ""
row "${DI}interface  ${N}${WH}wlan0${N}"
row "${DI}ip/subnet  ${N}${WH}192.168.4.12/24${N}"
row "${DI}gateway    ${N}${WH}192.168.4.1${N}"
row "${DI}ap bssid   ${N}${PU}D8:47:32:A1:9C:4F${N}"
row "${DI}frequency  ${N}${GR}5180 MHz${N}"
row "${DI}signal     ${N}${GR}-61 dBm${N}"
echo ""; line; echo ""
info "dns servers:"
row "${DI}Current DNS Server: 1.1.1.1${N}"
row "${DI}DNS Servers: 1.1.1.1 1.0.0.1${N}"
echo ""
info "routes:"
row "${DI}default via 192.168.4.1 dev wlan0 proto dhcp${N}"
row "${DI}192.168.4.0/24 dev wlan0 proto kernel scope link${N}"
echo ""
echo -ne "  ${DI}↵ continue${N} "; sleep 2.2; echo ""

# ── Menu → 2 (arp table) ─────────────────────────────────────────────────────
menu; sleep 0.9; type_out "2" 0.1

clear; echo ""
echo -e "  ${PU}◈ sniky-cho${N}  ${DI}›${N}  ${WH}arp table${N}"
echo -e "  ${DI}  hosts your machine already knows · zero packets sent${N}"
line; echo ""
tip "Only shows hosts your PC has already talked to. Use option ${WH}3${N}${CY} to discover more."
echo ""
printf "  ${WH}%-18s  %-20s  %-14s  %s${N}\n" "ip" "mac" "vendor" "state"
line
sleep 0.3
printf "  ${GR}%-18s  %-20s  %-14s  %s${N}\n"  "192.168.4.1"  "D8:47:32:A1:9C:4F" "TP-Link"       "REACHABLE"
sleep 0.2
printf "  ${GR}%-18s  %-20s  %-14s  %s${N}\n"  "192.168.4.3"  "3C:06:30:B7:E2:11" "Apple, Inc."   "REACHABLE"
sleep 0.2
printf "  ${DI}%-18s  %-20s  %-14s  %s${N}\n"  "192.168.4.8"  "B4:E6:2D:44:7A:90" "Samsung Elect" "STALE"
sleep 0.2
printf "  ${YE}%-18s  %-20s  %-14s  %s${N}\n"  "192.168.4.22" "F2:A3:9D:0C:11:3B" "randomized MAC" "REACHABLE"
echo ""
echo -ne "  ${DI}↵ continue${N} "; sleep 2.2; echo ""

# ── Menu → 6 (wifi scan) ─────────────────────────────────────────────────────
menu; sleep 0.9; type_out "6" 0.1

clear; echo ""
echo -e "  ${PU}◈ sniky-cho${N}  ${DI}›${N}  ${WH}wifi scan 802.11${N}"
echo -e "  ${DI}  nearby networks with channel, signal and security type${N}"
line; echo ""
tip "Same as your phone's WiFi scan — passive, does not associate to any network."
info "scanning nearby networks..."
echo ""; sleep 1.4

printf "  ${WH}%-32s  %-19s  %-5s  %-6s  %-22s  %s${N}\n" \
       "ssid" "bssid" "chan" "signal" "security" "vendor"
line
sleep 0.12
printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${PU}%-22s${N}  ${DI}%s${N}\n" \
       "HomeNetwork_5G"      "D8:47:32:A1:9C:4F" "36"  "90" "WPA3"       "TP-Link Technologies"
sleep 0.12
printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${GR}%-22s${N}  ${DI}%s${N}\n" \
       "HomeNetwork_2G"      "D8:47:32:A1:9C:4E" "6"   "76" "WPA2"       "TP-Link Technologies"
sleep 0.12
printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${GR}%-22s${N}  ${DI}%s${N}\n" \
       "Neighbor_Wifi_2G"    "B0:4E:26:D3:7A:11" "11"  "63" "WPA2"       "Huawei Technologies"
sleep 0.12
printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${GR}%-22s${N}  ${DI}%s${N}\n" \
       "ISP_Router_A4C2"     "AC:22:0B:3C:A4:C2" "1"   "49" "WPA2"       "Technicolor"
sleep 0.12
printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${YE}%-22s${N}  ${DI}%s${N}\n" \
       "CorpOffice_Secure"   "00:1A:2B:3C:4D:5E" "149" "41" "802.1X"     "Cisco Systems"
sleep 0.12
printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${RE}%-22s${N}  ${DI}%s${N}\n" \
       "DIRECT-old-printer"  "CC:3A:61:F9:02:8B" "6"   "34" "WPA1"       "Canon Inc."
sleep 0.12
printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${RE}%-22s${N}  ${DI}%s${N}\n" \
       "Free_Airport_Wifi"   "22:F1:7B:4D:CC:90" "1"   "27" "--"         "randomized"
echo ""
echo -e "  ${DI}legend:${N}  ${PU}■${N} WPA3  ${GR}■${N} WPA2  ${YE}■${N} 802.1X/Enterprise  ${RE}■${N} WPA1/Open"
echo ""
echo -ne "  ${DI}↵ continue${N} "; sleep 2.8; echo ""

# ── Menu → q ─────────────────────────────────────────────────────────────────
menu; sleep 1.0; type_out "q" 0.1
echo ""
ok "goodbye"
echo ""
