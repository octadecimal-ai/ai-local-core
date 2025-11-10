#!/bin/bash
# Skrypt ochrony konfiguracji WireGuard przed nadpisaniem przez rsync
# Dodaje pliki WireGuard do wykluczeń rsync

set -e

echo "🔒 Ochrona konfiguracji WireGuard przed rsync"
echo "=============================================="
echo ""

WG_DIR="$HOME/.wireguard"
EXCLUDE_FILE="$WG_DIR/.rsync-exclude"

# Utworzenie pliku wykluczeń
cat > "$EXCLUDE_FILE" <<EOF
# WireGuard configuration - NIE synchronizuj!
wg0.conf
*.key
private.key
public.key
logs/
*.log
EOF

echo "✅ Utworzono plik wykluczeń: $EXCLUDE_FILE"
echo ""

# Sprawdź czy istnieje rsync config
RSYNC_CONFIGS=(
    "$HOME/.rsyncrc"
    "$HOME/.rsync-filter"
    "$HOME/.config/rsync/exclude"
)

for config in "${RSYNC_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        echo "📝 Znaleziono konfigurację rsync: $config"
        
        # Sprawdź czy WireGuard jest już wykluczony
        if grep -q "wireguard\|\.wireguard" "$config" 2>/dev/null; then
            echo "   ✅ WireGuard już jest wykluczony"
        else
            echo "   ⚠️  WireGuard NIE jest wykluczony - dodaj ręcznie:"
            echo "      echo '.wireguard/' >> $config"
        fi
    fi
done

echo ""
echo "💡 Aby użyć wykluczeń w rsync:"
echo "   rsync --exclude-from=$EXCLUDE_FILE ..."
echo ""
echo "💡 Lub dodaj do .rsyncrc:"
echo "   exclude = .wireguard/"
echo ""

