#!/bin/bash

# =====================================================
# PROJECT: TOrchik v1.0 (STABLE EDITION)
# STYLE: TRON LEGACY / NEON GRID
# =====================================================

# Принудительно исправляем локаль для подавления предупреждений GTK/Qt
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Определяем рабочую директорию скрипта
BASE_DIR=$(dirname "$(readlink -f "$0")")

# --- ЦВЕТОВАЯ ПАЛИТРА ---
CYAN='\033[0;36m'
BRIGHT_CYAN='\033[1;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' 

# Файлы проекта
LOG_FILE="$BASE_DIR/TOrchik.log"
CONF_FILE="$BASE_DIR/torchik.conf"
TORRC="/etc/tor/torrc"
PCHAINS="/etc/proxychains4.conf"

# --- ИНИЦИАЛИЗАЦИЯ ЯЗЫКА ---
if [ ! -f "$CONF_FILE" ]; then
    clear
    echo -e "${BRIGHT_CYAN}Select Language / Выберите язык:${NC}"
    echo "1. English"
    echo "2. Русский"
    read -p ">> " lang_choice
    if [ "$lang_choice" == "2" ]; then
        echo "LANG=RU" > "$CONF_FILE"
    else
        echo "LANG=EN" > "$CONF_FILE"
    fi
fi

source "$CONF_FILE"

# --- СЛОВАРЬ (TRANSLATIONS) ---
if [ "$LANG" == "RU" ]; then
    T_INIT="[INITIALIZE] Полная настройка и запуск"
    T_NEWID="[NEW ID]     Сменить IP (Restart Tor)"
    T_CHECK="[CHECK]      Проверить IP (Real vs Tor)"
    T_RESTORE="[RESTORE]    Восстановить из бэкапа"
    T_MANUAL="[MANUAL]     Методичка Proxychains"
    T_EXIT="[EXIT]       Выход"
    T_WAIT="Ожидание синхронизации с сетью Tor..."
    T_SUCCESS="[УСПЕХ] Соединение установлено на 100%."
    T_IP_ERR="[ОШИБКА ПОЛУЧЕНИЯ IP]"
    T_LOG_OPEN="Открытие журнала Tor в новом окне..."
    T_CONF_APPLY="Записать новые мосты в конфигурацию? (y/n): "
    T_BACKUP="Создание резервной копии..."
    T_RESTORE_OK="Конфигурация восстановлена."
    T_RESTORE_ERR="Бэкап не найден."
    T_MAN_TITLE="=== МЕТОДИЧКА ПО PROXYCHAINS4 ==="
    T_MAN_TEXT="Proxychains направляет трафик приложений через Tor."
else
    T_INIT="[INITIALIZE] Full Setup & Start"
    T_NEWID="[NEW ID]     Change IP (Restart Tor)"
    T_CHECK="[CHECK]      Check IP (Real vs Tor)"
    T_RESTORE="[RESTORE]    Restore from Backup"
    T_MANUAL="[MANUAL]     Proxychains Manual"
    T_EXIT="[EXIT]       Exit"
    T_WAIT="Waiting for Tor network synchronization..."
    T_SUCCESS="[SUCCESS] Connection established at 100%."
    T_IP_ERR="[IP FETCH ERROR]"
    T_LOG_OPEN="Opening Tor logs in a new window..."
    T_CONF_APPLY="Apply new bridges to configuration? (y/n): "
    T_BACKUP="Creating backup..."
    T_RESTORE_OK="Configuration restored."
    T_RESTORE_ERR="Backup not found."
    T_MAN_TITLE="=== PROXYCHAINS4 MANUAL ==="
    T_MAN_TEXT="Proxychains redirects application traffic through Tor."
fi

# --- СИСТЕМНЫЕ ФУНКЦИИ ---

torchik_log() {
    local msg="[$(date +%H:%M:%S)] $1"
    echo -e "${CYAN}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

show_logo() {
    clear
    echo -e "${BRIGHT_CYAN}"
    echo "  _______ ____  _____   _____ _    _ _____ _  __"
    echo " |__   __/ __ \|  __ \ / ____| |  | |_   _| |/ /"
    echo "    | | | |  | | |__) | |    | |__| | | | | ' / "
    echo "    | | | |  | |  _  /| |    |  __  | | | |  <  "
    echo "    | | | |__| | | \ \| |____| |  | |_| |_| . \ "
    echo "    |_|  \____/|_|  \_\\______|_|  |_|_____|_|\_\\"
    echo -e "           >> SYSTEM: TOrchik v1.0 <<${NC}"
    echo -e "${BLUE}   [ DIR: $BASE_DIR ] [ LANG: $LANG ]${NC}\n"
}

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Run as root (sudo).${NC}"
  exit 1
fi

install_deps() {
    torchik_log "Updating APT lists..."
    apt-get update -qq
    apt-get install -y -qq tor proxychains4 curl obfs4proxy webtunnel libnotify-bin xterm > /dev/null
    torchik_log "Dependencies installed."
}

backup_system() {
    torchik_log "$T_BACKUP"
    cp "$TORRC" "${BASE_DIR}/torrc.bak" 2>/dev/null
    cp "$PCHAINS" "${BASE_DIR}/proxychains4.bak" 2>/dev/null
}

restore_system() {
    if [ -f "${BASE_DIR}/torrc.bak" ]; then
        cp "${BASE_DIR}/torrc.bak" "$TORRC"
        cp "${BASE_DIR}/proxychains4.bak" "$PCHAINS"
        systemctl restart tor
        torchik_log "$T_RESTORE_OK"
    else
        torchik_log "$T_RESTORE_ERR"
    fi
}

fetch_bridges() {
    torchik_log "Fetching bridges from Triplebit..."
    curl -s https://www.triplebit.org/bridges/ > /tmp/triplebit_raw.html
    grep -oP 'Bridge obfs4 [^<]+' /tmp/triplebit_raw.html | sed 's/ *$//' > /tmp/bridges.txt
    grep -oP 'webtunnel [^<]+' /tmp/triplebit_raw.html | sed 's/ *$//' | sed 's/^/Bridge /' >> /tmp/bridges.txt
    echo -e "${BRIGHT_CYAN}\n--- BRIDGES ---\n$(cat /tmp/bridges.txt)\n---------------${NC}"
}

configure_grid() {
    echo -e "${BLUE}\n[CURRENT TORRC]:${NC}"
    cat "$TORRC"
    echo -e "${BLUE}----------------${NC}"
    read -p "$T_CONF_APPLY" confirm
    if [[ $confirm == [yY] ]]; then
        backup_system
        cat <<EOF > "$TORRC"
UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
ClientTransportPlugin webtunnel exec /usr/bin/webtunnel
$(cat /tmp/bridges.txt)
EOF
        torchik_log "Torrc updated."
    fi
    cat <<EOF > "$PCHAINS"
strict_chain
proxy_dns 
remote_dns_res_ok
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
socks5  127.0.0.1 9050
EOF
}

wait_for_connection() {
    torchik_log "$T_WAIT"
    for i in {1..45}; do
        PROGRESS=$(journalctl -u tor@default -n 50 | grep -oP 'Bootstrapped \d+%' | tail -1)
        echo -ne "${CYAN}\r[PROGRESS]: $PROGRESS ${NC}"
        if journalctl -u tor@default -n 50 | grep -q "Bootstrapped 100%"; then
            echo -e "\n${BRIGHT_CYAN}$T_SUCCESS${NC}"
            sleep 3
            return 0
        fi
        sleep 2
    done
    return 1
}

launch_log_window() {
    torchik_log "$T_LOG_OPEN"
    # Принудительно передаем UTF-8 локаль в новое окно терминала
    local cmd="export LC_ALL=C.UTF-8; export LANG=C.UTF-8; sudo journalctl -u tor@default -f"
    
    if command -v xfce4-terminal >/dev/null; then
        xfce4-terminal --title="Tor Logs" -e "bash -c '$cmd'" &
    elif command -v qterminal >/dev/null; then
        qterminal -e "bash -c '$cmd'" &
    else
        xterm -title "Tor Logs" -e "bash -c '$cmd'" &
    fi
}

get_tor_ip() {
    local ip=$(proxychains4 -q curl -s --connect-timeout 12 ifconfig.me || proxychains4 -q curl -s --connect-timeout 12 ident.me)
    [ -z "$ip" ] && echo -e "${RED}$T_IP_ERR${NC}" || echo -e "${GREEN}$ip${NC}"
}

show_manual() {
    clear
    echo -e "${BRIGHT_CYAN}$T_MAN_TITLE${NC}"
    echo -e "${WHITE}$T_MAN_TEXT${NC}"
    if [ "$LANG" == "RU" ]; then
        echo -e "\n${YELLOW}Примеры:${NC}"
        echo -e "  proxychains4 firefox          - Браузер через Tor"
        echo -e "  proxychains4 nmap -sT -PN IP  - Сканирование (TCP)"
        echo -e "\n${RED}Важно:${NC} Tor не поддерживает UDP/ICMP (ping не работает)."
    else
        echo -e "\n${YELLOW}Examples:${NC}"
        echo -e "  proxychains4 firefox          - Browser via Tor"
        echo -e "  proxychains4 nmap -sT -PN IP  - Scanning (TCP)"
        echo -e "\n${RED}Note:${NC} Tor does NOT support UDP/ICMP (ping won't work)."
    fi
    read -p "Press Enter..."
}

# --- MAIN LOOP ---

run_cli() {
    while true; do
        show_logo
        echo -e "${CYAN}1. $T_INIT"
        echo -e "2. $T_NEWID"
        echo -e "3. $T_CHECK"
        echo -e "4. $T_RESTORE"
        echo -e "5. $T_MANUAL"
        echo -e "0. $T_EXIT"
        echo -e "${BLUE}----------------------------------------${NC}"
        read -p ">> " ch
        case $ch in
            1) install_deps; fetch_bridges; configure_grid; systemctl restart tor; wait_for_connection; launch_log_window; read -p "Enter..." ;;
            2) systemctl restart tor; wait_for_connection; echo -ne "${WHITE}New IP: ${NC}"; get_tor_ip; read -p "Enter..." ;;
            3) echo -e "${WHITE}REAL: ${RED}$(curl -s ifconfig.me)${NC}"; echo -ne "${WHITE}TOR:  ${BRIGHT_CYAN}"; get_tor_ip; read -p "Enter..." ;;
            4) restore_system; read -p "Enter..." ;;
            5) show_manual ;;
            0) exit 0 ;;
        esac
    done
}

run_cli
