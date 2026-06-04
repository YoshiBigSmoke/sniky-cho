#!/usr/bin/env bash
# sniky-cho — silent network reconnaissance

# ─── purple minimalist palette ───────────────────────────────────────────────
PU='\033[1;35m'   # bright purple   (primary accent)
PM='\033[0;35m'   # soft purple     (secondary)
GR='\033[0;32m'   # green           (ok / found)
YE='\033[0;33m'   # yellow          (warning)
RE='\033[0;31m'   # red             (error)
WH='\033[1;37m'   # bright white    (important value)
DI='\033[2;37m'   # dimmed grey     (secondary info)
CY='\033[0;36m'   # cyan            (tips / hints)
N='\033[0m'       # reset

# ─── global state ────────────────────────────────────────────────────────────
IFACE=""
MONITOR_MODE=0
OUI_DB="/usr/share/nmap/nmap-mac-prefixes"

# ────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ────────────────────────────────────────────────────────────────────────────

line()  { echo -e "${DI}  ────────────────────────────────────────────────────────${N}"; }
ok()    { echo -e "  ${GR}✓${N}  $*"; }
info()  { echo -e "  ${PM}·${N}  $*"; }
warn()  { echo -e "  ${YE}⚠${N}  $*"; }
err()   { echo -e "  ${RE}✗${N}  $*"; }
tip()   { echo -e "  ${CY}→${N}  $*"; }
row()   { echo -e "     $*"; }
pausa() { echo ""; echo -ne "  ${DI}↵ continue${N} "; read -r; }

get_gateway() { ip route show default | awk '/default/ {print $3}' | head -1; }
get_subnet()  { ip addr show "$IFACE" 2>/dev/null | awk '/inet / {print $2}' | head -1; }

need_iface() {
    if [[ -z "$IFACE" ]]; then
        err "No interface selected."
        tip "Use option ${WH}i${N}${CY} to choose your network adapter."
        pausa
        return 1
    fi
    return 0
}

oui_lookup() {
    local mac="$1"
    [[ -z "$mac" || "$mac" == "--" ]] && echo "unknown" && return
    local oui
    oui=$(echo "$mac" | tr -d ':' | tr 'a-f' 'A-F' | cut -c1-6)
    [[ ${#oui} -lt 6 ]] && echo "unknown" && return
    grep "^$oui" "$OUI_DB" 2>/dev/null | head -1 | cut -d' ' -f2- || echo "unknown"
}

titulo() {
    local title="$1"
    local desc="${2:-}"
    clear
    echo ""
    echo -e "  ${PU}◈ sniky-cho${N}  ${DI}›${N}  ${WH}${title}${N}"
    [[ -n "$desc" ]] && echo -e "  ${DI}  ${desc}${N}"
    line
    echo ""
}

# ────────────────────────────────────────────────────────────────────────────
# BANNER
# ────────────────────────────────────────────────────────────────────────────

banner() {
    clear
    echo ""
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
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN SCREEN
# ────────────────────────────────────────────────────────────────────────────

header() {
    clear
    echo ""

    if [[ -n "$IFACE" ]]; then
        local gw subnet ssid signal mon_tag=""
        gw=$(get_gateway)
        subnet=$(get_subnet)
        ssid=$(iw dev "$IFACE" link 2>/dev/null | awk '/SSID:/ {print $2}')
        signal=$(iw dev "$IFACE" link 2>/dev/null | awk '/signal:/ {print $2,$3}')
        [[ $MONITOR_MODE -eq 1 ]] && mon_tag="  ${YE}[monitor]${N}"

        echo -ne "  ${PU}◈ sniky-cho${N}  ${DI}·${N}  ${WH}${IFACE}${N}  ${DI}·${N}  ${WH}${subnet:-no ip}${N}  ${DI}·${N}  gw ${WH}${gw:-?}${N}"
        [[ -n "$ssid" ]]   && echo -ne "  ${DI}·${N}  ${PM}${ssid}${N}"
        [[ -n "$signal" ]] && echo -ne "  ${DI}·${N}  ${GR}${signal}${N}"
        echo -e "$mon_tag"
    else
        echo -e "  ${PU}◈ sniky-cho${N}  ${DI}·  no interface selected${N}"
        echo -e "  ${DI}              use option ${WH}i${DI} to get started${N}"
    fi

    echo ""
    line
    echo ""
}

menu() {
    header

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

# ────────────────────────────────────────────────────────────────────────────
# SELECT INTERFACE
# ────────────────────────────────────────────────────────────────────────────

sel_iface() {
    titulo "available interfaces" "pick the network adapter to use"

    local ifaces=()
    while IFS= read -r i; do ifaces+=("$i"); done \
        < <(ip link show | awk -F': ' '/^[0-9]/ && !/lo/ {print $2}' | tr -d ' ')

    local recommended=""
    for iface in "${ifaces[@]}"; do
        ip addr show "$iface" 2>/dev/null | grep -q 'inet ' && { recommended="$iface"; break; }
    done

    local n=1
    for iface in "${ifaces[@]}"; do
        local ip estado rec_tag=""
        ip=$(ip addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | head -1)
        estado=$(ip link show "$iface" | grep -o 'state [A-Z]*' | awk '{print $2}')
        [[ "$iface" == "$recommended" ]] && rec_tag="  ${GR}← recommended${N}"
        echo -e "  ${WH}${n}${N}  ${PU}${iface}${N}  ${DI}${ip:-no ip}  ${estado}${N}${rec_tag}"
        ((n++))
    done

    echo ""
    [[ -n "$recommended" ]] && tip "Interface ${WH}${recommended}${N}${CY} has an active connection."
    echo ""
    echo -ne "  ${PU}›${N} "
    read -r sel
    IFACE="${ifaces[$((sel-1))]}"
    [[ -z "$IFACE" ]] && warn "Invalid selection." && pausa && return
    ok "Interface set to: ${WH}${IFACE}${N}"
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 1 — NETWORK INFO
# ────────────────────────────────────────────────────────────────────────────

get_wan_ip() {
    local ip
    ip=$(curl -s --max-time 4 ifconfig.me 2>/dev/null)
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "$ip" && return
    ip=$(curl -s --max-time 4 checkip.amazonaws.com 2>/dev/null)
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "$ip" && return
    # fallback: SNMP WAN interface OID (ipAdEntAddr de la interfaz WAN)
    local gw; gw=$(get_gateway)
    if command -v snmpwalk &>/dev/null && [[ -n "$gw" ]]; then
        snmpwalk -v2c -c public -t 2 -r 0 "$gw" 1.3.6.1.2.1.4.20.1.1 2>/dev/null \
            | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
            | grep -vE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.|0\.)' \
            | head -1
    fi
}

mod_info() {
    titulo "network info" "fully passive · sends zero packets"
    need_iface || return

    local gw subnet bssid freq signal
    gw=$(get_gateway)
    subnet=$(get_subnet)
    bssid=$(iw dev "$IFACE" link 2>/dev/null | awk '/Connected to/ {print $3}')
    freq=$(iw dev "$IFACE" link 2>/dev/null | awk '/freq/ {print $2}')
    signal=$(iw dev "$IFACE" link 2>/dev/null | awk '/signal/ {print $2,$3}')

    info "fetching WAN IP..."
    local wan_ip
    wan_ip=$(get_wan_ip)

    row "${DI}interface  ${N}${WH}${IFACE}${N}"
    row "${DI}ip/subnet  ${N}${WH}${subnet}${N}"
    row "${DI}gateway    ${N}${WH}${gw}${N}"
    if [[ -n "$wan_ip" ]]; then
        row "${DI}wan ip     ${N}${GR}${wan_ip}${N}  ${DI}(ISP static/dynamic)${N}"
    else
        row "${DI}wan ip     ${N}${DI}unavailable (sin conexión a internet)${N}"
    fi
    row "${DI}ap bssid   ${N}${PU}${bssid}${N}"
    row "${DI}frequency  ${N}${GR}${freq} MHz${N}"
    row "${DI}signal     ${N}${GR}${signal}${N}"
    echo ""
    line
    echo ""

    info "dns servers:"
    resolvectl status "$IFACE" 2>/dev/null | grep -i "dns" | while IFS= read -r l; do
        row "${DI}${l}${N}"
    done
    echo ""

    info "routes:"
    ip route show | while IFS= read -r l; do row "${DI}${l}${N}"; done
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 2 — ARP TABLE
# ────────────────────────────────────────────────────────────────────────────

mod_arp() {
    titulo "arp table" "hosts your machine already knows · zero packets sent"
    need_iface || return

    tip "Only shows hosts your PC has already talked to. Use option ${WH}3${N}${CY} to discover more."
    echo ""

    printf "  ${WH}%-18s  %-20s  %-14s  %s${N}\n" "ip" "mac" "vendor" "state"
    line

    ip neigh show dev "$IFACE" 2>/dev/null | while read -r ip _ _ mac _ estado; do
        local vendor
        vendor=$(oui_lookup "$mac")
        local col="${GR}"
        [[ "$estado" =~ ^(STALE|FAILED|INCOMPLETE)$ ]] && col="${DI}"
        printf "  ${col}%-18s  %-20s  %-14s  %s${N}\n" "$ip" "$mac" "${vendor:0:14}" "$estado"
    done

    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 3 — PASSIVE CAPTURE
# ────────────────────────────────────────────────────────────────────────────

mod_pasiva() {
    need_iface || return
    local modo
    modo=$(iw dev "$IFACE" info 2>/dev/null | awk '/type/ {print $2}')
    if [[ "$modo" == "monitor" ]]; then
        _pasiva_monitor
    else
        _pasiva_managed
    fi
}

_pasiva_managed() {
    titulo "passive capture" "your machine listens · never transmits"

    tip "Captures broadcast/multicast traffic on your network — sends nothing."
    tip "For full 802.11 raw capture of all nearby devices, enable monitor mode ${WH}(option m)${N}${CY}."
    echo ""

    echo -ne "  ${WH}duration in seconds${N} ${DI}[default 300]${N}  › "
    read -r t; [[ -z "$t" ]] && t=300
    info "listening on ${WH}${IFACE}${N} for ${WH}${t}s${N}  ${DI}(≈ $(( t/60 )) min)${N}"
    echo ""

    local tmp_mac tmp_pair
    tmp_mac=$(mktemp /tmp/sc_mac_XXXXXX)
    tmp_pair=$(mktemp /tmp/sc_pair_XXXXXX)

    timeout "$t" tcpdump -i "$IFACE" -e -n -l 2>/dev/null | awk '
        function valid_mac(m) {
            return m ~ /^[0-9a-f]{2}(:[0-9a-f]{2}){5}$/ &&
                   m !~ /^(ff:ff:ff:ff:ff:ff|00:00:00:00:00:00|33:33|01:00)/
        }
        function valid_ip(ip) {
            return ip ~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ &&
                   ip !~ /^(0\.|127\.|224\.|239\.|255\.)/
        }
        /^[0-9]/ {
            src_mac = $2; dst_mac = $4
            gsub(/,/, "", dst_mac)

            src_ip = ""; dst_ip = ""
            for (i=5; i<=NF; i++) {
                f = $i; gsub(/[^0-9.]/, "", f)
                if (valid_ip(f) && src_ip == "") { src_ip = f; continue }
                if (valid_ip(f) && dst_ip == "") { dst_ip = f; break }
            }

            if (valid_mac(src_mac)) {
                print src_mac > "/dev/stderr"
                if (src_ip != "") print src_mac "\t" src_ip
            }
            if (valid_mac(dst_mac)) {
                print dst_mac > "/dev/stderr"
                if (dst_ip != "") print dst_mac "\t" dst_ip
            }
            fflush()
        }
    ' 2>>"$tmp_mac" >> "$tmp_pair" &

    local pid=$! elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${PM}·${N}  %ds / %ds   ${GR}%d${N} MACs" \
               "$elapsed" "$t" "$(sort -u "$tmp_mac" 2>/dev/null | wc -l)"
        sleep 1; ((elapsed++))
    done
    echo ""; echo ""

    ip neigh show dev "$IFACE" 2>/dev/null | awk '/lladdr/ {print $5"\t"$1}' >> "$tmp_pair"
    ip neigh show dev "$IFACE" 2>/dev/null | awk '/lladdr/ {print $5}' >> "$tmp_mac"

    local total
    total=$(sort -u "$tmp_mac" | grep -c .)
    ok "${WH}${total}${N} unique MACs detected"
    echo ""

    if [[ $total -eq 0 ]]; then
        warn "No devices detected."
        rm -f "$tmp_mac" "$tmp_pair"; pausa; return
    fi

    local subnet_prefix
    subnet_prefix=$(get_subnet | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')

    printf "  ${WH}%-20s  %-18s  %-22s  %s${N}\n" "mac" "associated ip" "vendor" "note"
    line

    sort -u "$tmp_mac" | grep -E '^[0-9a-f]{2}:' | while IFS= read -r mac; do
        local ip vendor nota col tipo_ip
        ip=$(grep "^${mac}	" "$tmp_pair" | awk '{print $2}' | sort | uniq -c | sort -rn | awk '{print $2}' | head -1)
        vendor=$(oui_lookup "$mac")

        local second="${mac:1:1}"
        if [[ "$second" =~ [2367aAbBeEfF] ]]; then
            col="${YE}"; vendor="randomized MAC"; nota="${DI}phone/tablet${N}"
        else
            col="${GR}"; nota=""
        fi

        if [[ -z "$ip" ]]; then
            ip="-"; tipo_ip=""
        elif [[ "$ip" == "${subnet_prefix}"* ]]; then
            tipo_ip=""
        else
            tipo_ip="${PM}internet${N}"
        fi

        printf "  ${col}%-20s${N}  ${WH}%-18s${N}  ${DI}%-22s${N}  %b%b\n" \
               "$mac" "$ip" "$vendor" "$nota" "$tipo_ip"
    done

    echo ""
    echo -e "  ${DI}legend:${N}  ${GR}■${N} real MAC  ${YE}■${N} randomized (privacy)"
    rm -f "$tmp_mac" "$tmp_pair"
    pausa
}

_pasiva_monitor() {
    titulo "passive capture" "raw 802.11 frame capture in monitor mode"

    tip "You will see MACs from every device transmitting nearby — not just your network."
    tip "Data is encrypted — only headers are captured, no content."
    echo ""

    local ap_bssid
    ap_bssid=$(ip neigh show dev "$IFACE" 2>/dev/null | awk '/lladdr/ {print $5}' | head -1)

    echo -ne "  ${WH}duration in seconds${N} ${DI}[default 60]${N}  › "
    read -r t; [[ -z "$t" ]] && t=60
    info "capturing 802.11 frames on ${WH}${IFACE}${N} for ${WH}${t}s${N}"
    echo ""

    local tmp_raw tmp_final
    tmp_raw=$(mktemp /tmp/sc_raw_XXXXXX)
    tmp_final=$(mktemp /tmp/sc_final_XXXXXX)

    timeout "$t" tcpdump -i "$IFACE" -e -n 2>/dev/null | \
        grep -oE '(SA|DA|TA):[0-9a-f]{2}(:[0-9a-f]{2}){5}' | \
        grep -oE '[0-9a-f]{2}(:[0-9a-f]{2}){5}' | \
        grep -vE '^(ff:ff:ff:ff:ff:ff|00:00:00:00:00:00|01:|33:33:|01:80:|01:00:5e:)' \
        >> "$tmp_raw" &

    local pid=$! elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${PM}·${N}  %ds / %ds   ${GR}%d${N} MACs" \
               "$elapsed" "$t" "$(sort -u "$tmp_raw" 2>/dev/null | wc -l)"
        sleep 1; ((elapsed++))
    done
    echo ""; echo ""

    sort -u "$tmp_raw" > "$tmp_final"
    local total; total=$(wc -l < "$tmp_final")
    ok "${WH}${total}${N} unique MACs"
    echo ""

    if [[ $total -eq 0 ]]; then
        warn "No MACs found. Verify the interface is in monitor mode."
        rm -f "$tmp_raw" "$tmp_final"; pausa; return
    fi

    printf "  ${WH}%-20s  %-26s  %s${N}\n" "mac" "vendor" "note"
    line
    while IFS= read -r mac; do
        local vendor nota col
        local second="${mac:1:1}"
        if [[ "$second" =~ [2367aAbBeEfF] ]]; then
            col="${YE}"; vendor="randomized MAC"
            nota="${DI}phone/tablet${N}"
        else
            col="${GR}"; vendor=$(oui_lookup "$mac")
            nota=""
        fi
        [[ "$mac" == "$ap_bssid" ]] && nota="${WH}AP${N}"
        printf "  ${col}%-20s${N}  ${WH}%-26s${N}  %b\n" "$mac" "$vendor" "$nota"
    done < "$tmp_final"

    echo ""
    echo -e "  ${DI}legend:${N}  ${GR}■${N} real MAC  ${YE}■${N} randomized  ${WH}■${N} AP"
    rm -f "$tmp_raw" "$tmp_final"
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 4 — mDNS
# ────────────────────────────────────────────────────────────────────────────

mod_mdns() {
    titulo "mdns / bonjour" "devices that announce themselves on the network"
    need_iface || return

    if ! command -v avahi-browse &>/dev/null; then
        err "avahi-browse not installed."
        tip "Install with:  ${WH}sudo pacman -S avahi${N}"
        pausa; return
    fi

    tip "mDNS works by listening to announcements — zero active packets."
    info "listening for mDNS services..."
    echo ""

    avahi-browse -a -t -r 2>/dev/null | grep -vE '^[=+]' | \
    grep -E "^\s*(hostname|address|service)" | \
    while IFS= read -r l; do
        if echo "$l" | grep -qi "hostname"; then
            echo -e "  ${PU}${l}${N}"
        elif echo "$l" | grep -qi "address"; then
            echo -e "  ${GR}${l}${N}"
        else
            echo -e "  ${DI}${l}${N}"
        fi
    done

    ok "done"
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 5 — OUI LOOKUP
# ────────────────────────────────────────────────────────────────────────────

mod_oui() {
    titulo "oui lookup" "identify the manufacturer of any device by MAC address"

    echo -ne "  ${WH}MAC address${N} ${DI}(or enter to use the ARP table)${N}  › "
    read -r input

    if [[ -z "$input" ]]; then
        need_iface || return
        info "MACs in ARP table for ${WH}${IFACE}${N}:"
        echo ""
        printf "  ${WH}%-18s  %-20s  %s${N}\n" "ip" "mac" "vendor"
        line
        ip neigh show dev "$IFACE" 2>/dev/null | while read -r ip _ _ mac _ estado; do
            local vendor
            vendor=$(oui_lookup "$mac")
            printf "  ${GR}%-18s${N}  ${PU}%-20s${N}  ${WH}%s${N}  ${DI}%s${N}\n" \
                   "$ip" "$mac" "$vendor" "$estado"
        done
    else
        local vendor
        vendor=$(oui_lookup "$input")
        echo ""
        row "${DI}mac     ${N}${PU}${input}${N}"
        row "${DI}vendor  ${N}${WH}${vendor}${N}"
    fi

    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 6 — WIFI SCAN 802.11
# ────────────────────────────────────────────────────────────────────────────

mod_wifi_scan() {
    titulo "wifi scan 802.11" "nearby networks with channel, signal and security type"
    need_iface || return

    tip "Same as your phone's WiFi scan — passive, does not associate to any network."
    info "scanning nearby networks..."
    echo ""

    local raw
    raw=$(nmcli -t -e yes -f BSSID,SSID,CHAN,SIGNAL,SECURITY dev wifi list 2>/dev/null)

    if [[ -z "$raw" ]]; then
        err "No results from nmcli. Verify that ${IFACE} is active."
        pausa; return
    fi

    printf "  ${WH}%-32s  %-19s  %-5s  %-6s  %-22s  %s${N}\n" \
           "ssid" "bssid" "chan" "signal" "security" "vendor"
    line

    echo "$raw" | while IFS= read -r raw_line; do
        [[ -z "${raw_line// }" ]] && continue
        local bssid ssid chan signal security vendor acol

        local parsed
        parsed=$(echo "$raw_line" | sed 's/\\:/§/g')
        IFS=':' read -r bssid ssid chan signal security <<< "$parsed"

        bssid=$(echo "$bssid" | sed 's/§/:/g')
        ssid=$(echo "$ssid"   | sed 's/§/:/g')
        [[ -z "$ssid" ]] && ssid="--"

        vendor=$(oui_lookup "$bssid")

        acol="${GR}"
        echo "$security" | grep -q "WPA3"    && acol="${PU}"
        echo "$security" | grep -q "802.1X"  && acol="${YE}"
        echo "$security" | grep -qE "^WPA2$" && acol="${GR}"
        echo "$security" | grep -qE "^WPA1"  && acol="${RE}"
        [[ -z "$security" || "$security" == "--" ]] && acol="${RE}"

        printf "  ${WH}%-32s${N}  ${DI}%-19s${N}  ${DI}%-5s${N}  ${DI}%-6s${N}  ${acol}%-22s${N}  ${DI}%s${N}\n" \
               "${ssid:0:32}" "$bssid" "$chan" "$signal" "$security" "${vendor:0:20}"
    done

    echo ""
    echo -e "  ${DI}legend:${N}  ${PU}■${N} WPA3  ${GR}■${N} WPA2  ${YE}■${N} 802.1X/Enterprise  ${RE}■${N} WPA1/Open"
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 7 — NMAP GATEWAY
# ────────────────────────────────────────────────────────────────────────────

mod_nmap() {
    titulo "nmap gateway" "semi-passive · sends probe packets to the router"
    need_iface || return

    local gw
    gw=$(get_gateway)
    [[ -z "$gw" ]] && err "No gateway detected." && pausa && return

    warn "Semi-passive: does send packets. The router may log this."
    echo ""
    echo -e "  target: ${WH}${gw}${N}"
    echo ""

    local PORTS="21,22,23,53,80,443,161,8080,8081,8443,8888,9000,9090,9443"
    echo -e "  ${WH}1${N}  quiet       ${DI}T2 · router ports · ~10s${N}"
    echo -e "  ${WH}2${N}  balanced    ${DI}T3 · router ports · ~5s${N}"
    echo -e "  ${WH}3${N}  full        ${DI}T2 · top 1000 ports · ~2min${N}"
    echo ""
    echo -ne "  ${PU}›${N} "
    read -r vel

    local timing ports
    case "$vel" in
        2) timing="-T3"; ports="-p $PORTS" ;;
        3) timing="-T2"; ports="--top-ports 1000" ;;
        *) timing="-T2"; ports="-p $PORTS" ;;
    esac

    echo ""
    info "scanning ${WH}${gw}${N}  ${DI}(Ctrl+C to cancel)${N}"
    line; echo ""

    nmap -Pn $timing $ports -sV --version-intensity 1 --open "$gw" 2>&1 | \
    while IFS= read -r l; do
        if echo "$l" | grep -qE "/tcp.*open|/udp.*open"; then
            echo -e "  ${GR}${l}${N}"
        elif echo "$l" | grep -q "Nmap scan report"; then
            echo -e "  ${WH}${l}${N}"
        elif echo "$l" | grep -q "MAC Address"; then
            echo -e "  ${PU}${l}${N}"
        elif echo "$l" | grep -qE "Service Info|OS:"; then
            echo -e "  ${YE}${l}${N}"
        else
            echo -e "  ${DI}${l}${N}"
        fi
    done
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 8 — BANNER GRAB
# ────────────────────────────────────────────────────────────────────────────

mod_banner() {
    titulo "banner grab" "reads router version by connecting to its ports"
    need_iface || return

    local gw
    gw=$(get_gateway)
    [[ -z "$gw" ]] && err "No gateway detected." && pausa && return

    local gw_mac vendor
    gw_mac=$(ip neigh show "$gw" 2>/dev/null | awk '/lladdr/ {print $5}' | head -1)
    vendor=$(oui_lookup "$gw_mac")

    warn "Semi-passive: establishes real TCP connections to the router."
    echo ""
    info "target: ${WH}${gw}${N}  ${DI}vendor: ${vendor}${N}"
    echo ""

    echo -e "  ${PM}── HTTP :80 ${DI}──────────────────────────────────${N}"
    local http_resp
    http_resp=$(timeout 4 bash -c "exec 3<>/dev/tcp/$gw/80; printf 'HEAD / HTTP/1.0\r\nHost: $gw\r\nUser-Agent: Mozilla/5.0\r\n\r\n' >&3; timeout 3 cat <&3" 2>/dev/null)
    if [[ -n "$http_resp" ]]; then
        echo "$http_resp" | head -20 | while IFS= read -r l; do
            if echo "$l" | grep -qiE "server:|x-powered|location|www-auth"; then
                echo -e "  ${GR}${l}${N}"
            else
                echo -e "  ${DI}${l}${N}"
            fi
        done
    else
        row "${DI}no response${N}"
    fi
    echo ""

    echo -e "  ${PM}── HTTPS :443 ${DI}────────────────────────────────${N}"
    local https_resp
    https_resp=$(timeout 4 curl -sk -o /dev/null -D - --max-time 3 "https://$gw" 2>/dev/null | head -20)
    if [[ -n "$https_resp" ]]; then
        echo "$https_resp" | while IFS= read -r l; do
            if echo "$l" | grep -qiE "server:|x-powered|location"; then
                echo -e "  ${GR}${l}${N}"
            else
                echo -e "  ${DI}${l}${N}"
            fi
        done
    else
        row "${DI}no response${N}"
    fi
    echo ""

    echo -e "  ${PM}── SSH :22 ${DI}───────────────────────────────────${N}"
    local ssh_resp
    ssh_resp=$(timeout 3 bash -c "exec 3<>/dev/tcp/$gw/22; timeout 2 cat <&3" 2>/dev/null | head -3)
    if [[ -n "$ssh_resp" ]]; then
        echo -e "  ${GR}${ssh_resp}${N}"
    else
        row "${DI}closed or no response${N}"
    fi
    echo ""

    echo -e "  ${PM}── Telnet :23 ${DI}────────────────────────────────${N}"
    local tel_resp
    tel_resp=$(timeout 3 bash -c "exec 3<>/dev/tcp/$gw/23; timeout 2 cat <&3" 2>/dev/null | strings | head -5)
    if [[ -n "$tel_resp" ]]; then
        echo -e "  ${YE}[open]${N}"
        echo "$tel_resp" | while IFS= read -r l; do row "${GR}${l}${N}"; done
    else
        row "${DI}closed or no response${N}"
    fi
    echo ""

    echo -e "  ${PM}── HTTP :8080 ${DI}────────────────────────────────${N}"
    local alt_resp
    alt_resp=$(timeout 4 bash -c "exec 3<>/dev/tcp/$gw/8080; printf 'HEAD / HTTP/1.0\r\nHost: $gw\r\n\r\n' >&3; timeout 3 cat <&3" 2>/dev/null | head -10)
    if [[ -n "$alt_resp" ]]; then
        echo "$alt_resp" | while IFS= read -r l; do
            echo -e "  ${GR}${l}${N}"
        done
    else
        row "${DI}closed or no response${N}"
    fi

    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 9 — SNMP
# ────────────────────────────────────────────────────────────────────────────

mod_snmp() {
    titulo "snmp" "queries internal router info if SNMP is enabled"
    need_iface || return

    if ! command -v snmpwalk &>/dev/null; then
        err "snmpwalk not installed."
        tip "Install with:  ${WH}sudo pacman -S net-snmp${N}"
        pausa; return
    fi

    local gw
    gw=$(get_gateway)
    [[ -z "$gw" ]] && err "No gateway detected." && pausa && return

    warn "Semi-passive: sends UDP queries to the router."
    tip "Most modern routers have SNMP disabled — no response is normal."
    echo ""
    info "target: ${WH}${gw}${N}  ${DI}community strings: public, private${N}"
    echo ""

    local oids=(
        "1.3.6.1.2.1.1.1.0"
        "1.3.6.1.2.1.1.4.0"
        "1.3.6.1.2.1.1.5.0"
        "1.3.6.1.2.1.1.6.0"
        "1.3.6.1.2.1.1.3.0"
    )
    local labels=("description" "contact" "name" "location" "uptime")
    local found=0

    for community in public private; do
        echo -ne "  ${PM}·${N}  trying community ${WH}${community}${N}..."

        local test
        test=$(snmpget -v2c -c "$community" -t 1 -r 0 "$gw" "1.3.6.1.2.1.1.1.0" 2>/dev/null)
        if [[ -z "$test" ]]; then
            echo -e "  ${DI}no response${N}"
            continue
        fi

        echo -e "  ${GR}responds!${N}"
        echo -e "  ${PM}── community: ${community} ${DI}─────────────────────${N}"

        local i=0
        for oid in "${oids[@]}"; do
            local val
            val=$(snmpget -v2c -c "$community" -t 1 -r 0 "$gw" "$oid" 2>/dev/null | cut -d'=' -f2- | xargs)
            if [[ -n "$val" && "$val" != *"No Such"* ]]; then
                printf "  ${GR}%-12s${N}  ${WH}%s${N}\n" "${labels[$i]}" "$val"
                found=1
            fi
            ((i++))
        done
        echo ""
    done

    if [[ $found -eq 0 ]]; then
        warn "SNMP blocked or disabled on this router."
        info "Common on modern routers and enterprise networks."
    fi

    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# 0 — REVERSE DNS
# ────────────────────────────────────────────────────────────────────────────

mod_rdns() {
    titulo "reverse dns" "resolves the domain name of the gateway"
    need_iface || return

    local gw
    gw=$(get_gateway)
    [[ -z "$gw" ]] && err "No gateway detected." && pausa && return

    tip "The PTR record often reveals the ISP and sometimes the router's location."
    echo ""

    row "${DI}gateway   ${N}${WH}${gw}${N}"
    row "${DI}ptr       ${N}${GR}$(dig -x "$gw" +short 2>/dev/null || echo "no result")${N}"
    echo ""
    line; echo ""
    dig -x "$gw" 2>/dev/null | grep -v '^;' | grep -v '^$' | while IFS= read -r l; do
        row "${DI}${l}${N}"
    done
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# MONITOR MODE
# ────────────────────────────────────────────────────────────────────────────

mod_monitor() {
    titulo "monitor mode" "raw 802.11 capture · temporarily disconnects wifi"
    need_iface || return

    if [[ $EUID -ne 0 ]]; then
        err "Root privileges required to change interface mode."
        tip "Run the script with ${WH}sudo${N}${CY} to use this feature."
        pausa; return
    fi

    local modo_actual
    modo_actual=$(iw dev "$IFACE" info 2>/dev/null | awk '/type/ {print $2}')

    row "${DI}interface    ${N}${WH}${IFACE}${N}"
    row "${DI}current mode ${N}${WH}${modo_actual}${N}"
    echo ""

    if [[ "$modo_actual" == "monitor" ]]; then
        echo -ne "  ${WH}Disable monitor mode?${N} ${DI}[y/N]${N}  › "
        read -r c
        [[ "$c" != "y" && "$c" != "Y" ]] && return

        info "bringing interface down..."
        ip link set "$IFACE" down
        iw dev "$IFACE" set type managed
        ip link set "$IFACE" up

        info "returning control to NetworkManager..."
        nmcli dev set "$IFACE" managed yes 2>/dev/null

        info "reconnecting to network..."
        nmcli dev connect "$IFACE" 2>/dev/null &
        sleep 3

        ok "Managed mode restored — reconnecting."
        MONITOR_MODE=0
    else
        warn "Monitor mode will disconnect WiFi while active."
        tip "An Alfa adapter is recommended — it lets you keep a second interface connected."
        echo -ne "  ${WH}Enable monitor mode?${N} ${DI}[y/N]${N}  › "
        read -r c
        [[ "$c" != "y" && "$c" != "Y" ]] && return

        info "releasing ${IFACE} from NetworkManager..."
        nmcli dev set "$IFACE" managed no 2>/dev/null

        info "enabling monitor mode..."
        ip link set "$IFACE" down
        iw dev "$IFACE" set type monitor
        ip link set "$IFACE" up

        local nuevo
        nuevo=$(iw dev "$IFACE" info 2>/dev/null | awk '/type/ {print $2}')
        if [[ "$nuevo" == "monitor" ]]; then
            ok "Monitor mode active on ${WH}${IFACE}${N}"
            ok "NetworkManager paused — it will not revert the mode."
            MONITOR_MODE=1
        else
            err "Could not activate. Current state: ${YE}${nuevo}${N}"
            nmcli dev set "$IFACE" managed yes 2>/dev/null
        fi
    fi
    pausa
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN LOOP
# ────────────────────────────────────────────────────────────────────────────

[[ $EUID -ne 0 ]] && echo -e "\n  ${YE}⚠${N}  Some features require sudo  ${DI}(monitor mode, tcpdump)${N}\n"

# auto-detect WiFi interface on startup
auto=$(ip link show | awk -F': ' '/^[0-9]/ && !/lo/ {print $2}' | tr -d ' ' | head -1)
[[ -n "$auto" ]] && IFACE="$auto"

# welcome screen
banner
if [[ -n "$IFACE" ]]; then
    ok "Auto-detected interface: ${WH}${IFACE}${N}  ${DI}(change with option i if needed)${N}"
else
    warn "No interface detected. Use option ${WH}i${N}${YE} to select one."
fi
echo ""
pausa

while true; do
    menu
    read -r op
    case "$op" in
        1) mod_info ;;
        2) mod_arp ;;
        3) mod_pasiva ;;
        4) mod_mdns ;;
        5) mod_oui ;;
        6) mod_wifi_scan ;;
        7) mod_nmap ;;
        8) mod_banner ;;
        9) mod_snmp ;;
        0) mod_rdns ;;
        i|I) sel_iface ;;
        m|M) mod_monitor ;;
        q|Q) echo ""; ok "goodbye"; echo ""; exit 0 ;;
        *) warn "Invalid option."; sleep 0.8 ;;
    esac
done
