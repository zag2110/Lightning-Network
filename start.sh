#!/bin/bash
# Script pour démarrer Bitcoin Core et Core Lightning

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================="
echo "Démarrage Lightning Network Stack"
echo "========================================="
echo ""

# 1. Vérifier si Bitcoin Core est déjà démarré
if pgrep -x "bitcoind" > /dev/null; then
    log_warn "Bitcoin Core est déjà en cours d'exécution"
else
    log_info "Démarrage de Bitcoin Core (testnet4)..."
    bitcoind -daemon
    sleep 3
    
    if pgrep -x "bitcoind" > /dev/null; then
        log_info "✓ Bitcoin Core démarré"
    else
        log_error "✗ Échec du démarrage de Bitcoin Core"
        log_error "Vérifiez les logs : tail -f ~/.bitcoin/testnet4/debug.log"
        exit 1
    fi
fi

# 2. Vérifier l'état de la synchronisation
log_info "Vérification de la synchronisation Bitcoin..."
SYNCED=$(bitcoin-cli -testnet4 getblockchaininfo 2>/dev/null | grep -o '"initialblockdownload": [^,]*' | grep -o '[^:]*$' | tr -d ' ')

if [[ "$SYNCED" == "true" ]]; then
    log_warn "Bitcoin Core est en cours de synchronisation initiale"
    log_warn "Cela peut prendre plusieurs heures..."
    BLOCKS=$(bitcoin-cli -testnet4 getblockchaininfo | grep -o '"blocks": [0-9]*' | grep -o '[0-9]*')
    log_info "Blocs téléchargés : $BLOCKS"
elif [[ "$SYNCED" == "false" ]]; then
    log_info "✓ Bitcoin Core synchronisé"
else
    log_warn "Impossible de vérifier l'état de synchronisation"
fi

echo ""

# 3. Vérifier si Core Lightning est déjà démarré
if pgrep -x "lightningd" > /dev/null; then
    log_warn "Core Lightning est déjà en cours d'exécution"
else
    log_info "Démarrage de Core Lightning (testnet4)..."
    lightningd --network=testnet4 --daemon
    sleep 3
    
    if pgrep -x "lightningd" > /dev/null; then
        log_info "✓ Core Lightning démarré"
    else
        log_error "✗ Échec du démarrage de Core Lightning"
        log_error "Vérifiez les logs : tail -f /tmp/lightningd.log"
        exit 1
    fi
fi

# 4. Afficher les informations du nœud
echo ""
log_info "Informations du nœud Lightning :"
lightning-cli --network=testnet4 getinfo 2>/dev/null || log_warn "Impossible de récupérer les infos du nœud"

echo ""
echo "========================================="
echo "✓ Services démarrés"
echo "========================================="
echo ""
echo "Commandes utiles :"
echo ""
echo "  Bitcoin Core :"
echo "    bitcoin-cli -testnet4 getblockchaininfo"
echo "    bitcoin-cli -testnet4 getwalletinfo"
echo "    bitcoin-cli -testnet4 stop"
echo ""
echo "  Core Lightning :"
echo "    lightning-cli --network=testnet4 getinfo"
echo "    lightning-cli --network=testnet4 listfunds"
echo "    lightning-cli --network=testnet4 stop"
echo ""
echo "  Logs :"
echo "    tail -f ~/.bitcoin/testnet4/debug.log"
echo "    tail -f /tmp/lightningd.log"
echo ""
