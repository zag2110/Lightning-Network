#!/bin/bash
# Script pour arrêter Bitcoin Core et Core Lightning

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================="
echo "Arrêt Lightning Network Stack"
echo "========================================="
echo ""

# 1. Arrêter Core Lightning
if pgrep -x "lightningd" > /dev/null; then
    log_info "Arrêt de Core Lightning..."
    lightning-cli --network=testnet4 stop 2>/dev/null
    sleep 2
    
    if ! pgrep -x "lightningd" > /dev/null; then
        log_info "✓ Core Lightning arrêté"
    else
        log_error "✗ Core Lightning ne s'est pas arrêté proprement"
    fi
else
    log_info "Core Lightning n'est pas en cours d'exécution"
fi

echo ""

# 2. Arrêter Bitcoin Core
if pgrep -x "bitcoind" > /dev/null; then
    log_info "Arrêt de Bitcoin Core..."
    bitcoin-cli -testnet4 stop 2>/dev/null
    
    # Attendre que le processus se termine (max 30 secondes)
    for i in {1..30}; do
        if ! pgrep -x "bitcoind" > /dev/null; then
            log_info "✓ Bitcoin Core arrêté"
            break
        fi
        sleep 1
    done
    
    if pgrep -x "bitcoind" > /dev/null; then
        log_error "✗ Bitcoin Core ne s'est pas arrêté proprement"
    fi
else
    log_info "Bitcoin Core n'est pas en cours d'exécution"
fi

echo ""
echo "========================================="
echo "✓ Services arrêtés"
echo "========================================="
