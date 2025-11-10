# 🔑 Wyjaśnienie kluczy WireGuard

## Różnica między kluczami

### Lokalny PC (MacOS)
- **Klucz prywatny lokalny** - już wygenerowany, w `~/.wireguard/wg0.conf`
- **Klucz publiczny lokalny** - już wygenerowany, **ten idzie na serwer OVH**

### Serwer OVH
- **Klucz prywatny serwera** - musi być wygenerowany na serwerze
- **Klucz publiczny serwera** - **ten idzie do lokalnej konfiguracji** (to jest SERVER_PUBLIC_KEY)

## Jak to działa

```
[Lokalny PC]                    [Serwer OVH]
┌─────────────────┐            ┌─────────────────┐
│ Klucz prywatny  │            │ Klucz prywatny  │
│ lokalny         │            │ serwera         │
│                 │            │                 │
│ Klucz publiczny │  ────────> │ Klucz publiczny │
│ lokalny ────────┼───────────>│ serwera         │
│                 │            │                 │
│ Konfiguracja:   │            │ Konfiguracja:   │
│ - Mój klucz     │            │ - Mój klucz     │
│   prywatny      │            │   prywatny       │
│ - Klucz         │            │ - Klucz         │
│   publiczny     │            │   publiczny     │
│   SERWERA       │            │   LOKALNEGO PC   │
└─────────────────┘            └─────────────────┘
```

## Co masz już gotowe

### Lokalnie (MacOS)
✅ Klucz prywatny lokalny - wygenerowany  
✅ Klucz publiczny lokalny - wygenerowany  
✅ Konfiguracja lokalna - utworzona (ale nie uzupełniona)

**Twój lokalny klucz publiczny:**
```bash
# Możesz go wygenerować z konfiguracji:
LOCAL_PRIVATE_KEY=$(grep "PrivateKey" ~/.wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
echo "$LOCAL_PRIVATE_KEY" | wg pubkey
```

**Ten klucz musisz dodać do konfiguracji serwera OVH!**

## Czego potrzebujesz

### SERVER_PUBLIC_KEY (klucz publiczny serwera OVH)

**Opcja 1: Jeśli serwer jest już skonfigurowany**
```bash
ssh waldus-server
sudo cat /etc/wireguard/public.key
```

**Opcja 2: Jeśli serwer nie jest jeszcze skonfigurowany**
```bash
ssh waldus-server
sudo bash /tmp/wireguard-server-config.sh <TWÓJ_LOKALNY_KLUCZ_PUBLICZNY>
# Skrypt wyświetli klucz publiczny serwera - skopiuj go
```

## Krok po kroku

### 1. Pobierz swój lokalny klucz publiczny
```bash
LOCAL_PRIVATE_KEY=$(grep "PrivateKey" ~/.wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
LOCAL_PUBLIC_KEY=$(echo "$LOCAL_PRIVATE_KEY" | wg pubkey)
echo "Twój lokalny klucz publiczny (dla serwera):"
echo "$LOCAL_PUBLIC_KEY"
```

### 2. Skonfiguruj serwer OVH
```bash
# Skopiuj skrypt na serwer (już skopiowany)
ssh waldus-server

# Uruchom skrypt z TWOIM lokalnym kluczem publicznym
sudo bash /tmp/wireguard-server-config.sh <TWÓJ_LOKALNY_KLUCZ_PUBLICZNY>
```

### 3. Skopiuj klucz publiczny serwera
Po uruchomieniu skryptu, skopiuj klucz publiczny serwera (będzie wyświetlony).

### 4. Uzupełnij konfigurację lokalną
```bash
./scripts/complete-wireguard.sh <SERVER_PUBLIC_KEY>
```

## Podsumowanie

- **SERVER_PUBLIC_KEY** = Klucz publiczny **SERWERA OVH** (nie Twój!)
- **Twój lokalny klucz publiczny** = Idzie do konfiguracji serwera
- **Klucz prywatny** = Nigdy nie udostępniaj! Zostaje na swoim urządzeniu

## Bezpieczeństwo

⚠️ **WAŻNE:**
- Klucz prywatny = **NIGDY nie udostępniaj**
- Klucz publiczny = Możesz bezpiecznie udostępniać
- Każde urządzenie ma swój własny klucz prywatny i publiczny

