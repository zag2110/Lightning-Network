#!/bin/bash
# Script pour démarrer toute l'infrastructure Lightning Network

set -e

echo "================================================"
echo "Démarrage de l'infrastructure Lightning Network"
echo "================================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Vérifier et démarrer Bitcoin Core
echo -e "${YELLOW}[1/4]${NC} Vérification de Bitcoin Core..."
if ! pgrep -x "bitcoind" > /dev/null; then
    echo "Démarrage de Bitcoin Core..."
    bitcoind -testnet4 -daemon
    sleep 3
else
    echo -e "${GREEN}✓${NC} Bitcoin Core déjà en cours d'exécution"
fi

# Attendre que Bitcoin soit prêt
echo "Attente de Bitcoin RPC..."
for i in {1..10}; do
    if bitcoin-cli -testnet4 getblockchaininfo > /dev/null 2>&1; then
        BLOCKS=$(bitcoin-cli -testnet4 getblockchaininfo | grep '"blocks"' | awk '{print $2}' | tr -d ',')
        echo -e "${GREEN}✓${NC} Bitcoin Core prêt (Blocs: $BLOCKS)"
        break
    fi
    sleep 1
done

# Charger le wallet
echo "Chargement du wallet..."
bitcoin-cli -testnet4 loadwallet testwallet 2>/dev/null || echo "Wallet déjà chargé"
BALANCE=$(bitcoin-cli -testnet4 -rpcwallet=testwallet getbalance)
echo -e "${GREEN}✓${NC} Balance: $BALANCE BTC"

# 2. Démarrer Core Lightning
echo -e "\n${YELLOW}[2/4]${NC} Démarrage de Core Lightning..."
pkill -9 lightningd 2>/dev/null || true
sleep 2
rm -f ~/.lightning/testnet4/.lock

nohup lightningd --network=testnet4 > /tmp/lightning.out 2>&1 &
LIGHTNING_PID=$!
echo "Lightning PID: $LIGHTNING_PID"

# Attendre que Lightning soit prêt
echo "Attente de Lightning RPC (15 secondes)..."
sleep 15

if lightning-cli --network=testnet4 getinfo > /dev/null 2>&1; then
    NODE_ID=$(lightning-cli --network=testnet4 getinfo | grep '"id"' | head -1 | awk '{print $2}' | tr -d '",')
    echo -e "${GREEN}✓${NC} Lightning prêt"
    echo "Node ID: $NODE_ID"
else
    echo -e "${RED}✗${NC} Lightning n'a pas démarré correctement"
    echo "Logs:"
    tail -20 /tmp/lightning.out
    exit 1
fi

# 3. Afficher l'état des canaux
echo -e "\n${YELLOW}[3/4]${NC} État des canaux Lightning..."
CHANNELS=$(lightning-cli --network=testnet4 listfunds | grep '"state"' | wc -l)
echo "Nombre de canaux: $CHANNELS"
if [ "$CHANNELS" -gt 0 ]; then
    lightning-cli --network=testnet4 listfunds | grep -A 5 '"state"' || true
fi

# 4. Instructions pour démarrer le serveur
echo -e "\n${YELLOW}[4/4]${NC} Pour démarrer le serveur LNURL:"
echo ""
echo "  cd ~/LN_version_2/lnurl-server"
echo "  ./target/release/server"
echo ""
echo -e "${GREEN}Infrastructure prête !${NC}"
echo ""
echo "================================================"
echo "Commandes utiles:"
echo "================================================"
echo ""
echo "Bitcoin:"
echo "  bitcoin-cli -testnet4 -rpcwallet=testwallet getbalance"
echo "  bitcoin-cli -testnet4 -rpcwallet=testwallet getnewaddress"
echo ""
echo "Lightning:"
echo "  lightning-cli --network=testnet4 getinfo"
echo "  lightning-cli --network=testnet4 listfunds"
echo "  lightning-cli --network=testnet4 listpeers"
echo ""
echo "Serveur LNURL:"
echo "  cd ~/LN_version_2/lnurl-server && ./target/release/server"
echo ""
