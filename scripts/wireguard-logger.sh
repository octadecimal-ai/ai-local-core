#!/bin/bash
# Logger dla WireGuard - zapisuje wszystkie zdarzenia do pliku

LOG_DIR="$HOME/.wireguard/logs"
LOG_FILE="$LOG_DIR/wireguard.log"
mkdir -p "$LOG_DIR"

log() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] $*" | tee -a "$LOG_FILE"
}

log_error() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# Sprawdź status WireGuard
check_wireguard() {
    log "Sprawdzanie statusu WireGuard..."
    
    if command -v wg >/dev/null 2>&1; then
        WG_STATUS=$(wg show 2>&1)
        if [ -z "$WG_STATUS" ]; then
            log_error "WireGuard nie jest uruchomiony"
            return 1
        else
            log "WireGuard działa:"
            echo "$WG_STATUS" | while read line; do
                log "  $line"
            done
            return 0
        fi
    else
        log_error "WireGuard nie jest zainstalowany"
        return 1
    fi
}

# Sprawdź konfigurację
check_config() {
    CONFIG_FILE="$HOME/.wireguard/wg0.conf"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Plik konfiguracyjny nie istnieje: $CONFIG_FILE"
        return 1
    fi
    
    log "Sprawdzanie konfiguracji: $CONFIG_FILE"
    
    if grep -q "<SERVER_PUBLIC_KEY>" "$CONFIG_FILE"; then
        log_error "Konfiguracja nie jest uzupełniona - brak klucza serwera"
        return 1
    fi
    
    log "Konfiguracja wygląda poprawnie"
    return 0
}

# Test połączenia
test_connection() {
    SERVER_IP=${1:-10.0.0.1}
    
    log "Test połączenia do $SERVER_IP..."
    
    if ping -c 1 -W 2 "$SERVER_IP" >/dev/null 2>&1; then
        log "✅ Ping do $SERVER_IP działa"
    else
        log_error "❌ Ping do $SERVER_IP nie działa"
    fi
    
    if curl -s --max-time 5 "http://$SERVER_IP:11434/api/tags" >/dev/null 2>&1; then
        log "✅ Ollama dostępne na http://$SERVER_IP:11434"
    else
        log_error "❌ Ollama nie odpowiada na http://$SERVER_IP:11434"
    fi
}

# Sprawdź czy rsync może nadpisać konfigurację
check_rsync() {
    log "Sprawdzanie procesów rsync..."
    
    RSYNC_PROCESSES=$(ps aux | grep rsync | grep -v grep)
    if [ -n "$RSYNC_PROCESSES" ]; then
        log_error "Znaleziono procesy rsync (mogą nadpisywać konfigurację):"
        echo "$RSYNC_PROCESSES" | while read line; do
            log "  $line"
        done
        return 1
    else
        log "Brak aktywnych procesów rsync"
        return 0
    fi
}

# Główna funkcja
main() {
    log "=== Sprawdzanie WireGuard VPN ==="
    
    check_wireguard
    WG_STATUS=$?
    
    check_config
    CONFIG_STATUS=$?
    
    if [ $WG_STATUS -eq 0 ] && [ $CONFIG_STATUS -eq 0 ]; then
        test_connection
    fi
    
    check_rsync
    
    log "=== Koniec sprawdzania ==="
    echo ""
    echo "Logi zapisane w: $LOG_FILE"
}

main "$@"

