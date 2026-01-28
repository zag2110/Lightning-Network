#!/bin/bash
# Script pour maintenir Lightning et le serveur LNURL en fonctionnement

echo "================================================"
echo "  Démarrage infrastructure LNURL (stable)"
echo "================================================"
echo ""

# Nettoyer les processus précédents
pkill -9 lightningd 2>/dev/null
pkill -f "target/release/server" 2>/dev/null
rm -f ~/.lightning/testnet4/.lock ~/.lightning/testnet4/lightning-rpc
sleep 2

# Vérifier Bitcoin
echo "1. Vérification Bitcoin Core..."
if ! bitcoin-cli -testnet4 getblockcount > /dev/null 2>&1; then
    echo "   ❌ Bitcoin Core n'est pas actif!"
    exit 1
fi
BLOCKS=$(bitcoin-cli -testnet4 getblockcount)
echo "   ✅ Bitcoin Core actif ($BLOCKS blocs)"
echo ""

# Démarrer Lightning
echo "2. Démarrage Core Lightning..."
lightningd --network=testnet4 --daemon
sleep 8

# Vérifier Lightning une fois
if lightning-cli --network=testnet4 getinfo > /dev/null 2>&1; then
    NODE_ID=$(lightning-cli --network=testnet4 getinfo | grep -o '"id"[^,]*' | cut -d'"' -f4)
    echo "   ✅ Lightning actif"
    echo "   Node ID: ${NODE_ID:0:20}..."
else
    echo "   ❌ Lightning ne démarre pas"
    tail -20 ~/.lightning/testnet4/lightning.log
    exit 1
fi
echo ""

# Démarrer le serveur LNURL RAPIDEMENT
echo "3. Démarrage serveur LNURL (immédiat)..."
cd ~/LN_version_2/lnurl-server
./target/release/server > /tmp/lnurl-server.log 2>&1 &
SERVER_PID=$!
sleep 3

# Vérifier le serveur
if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo "   ✅ Serveur actif (PID: $SERVER_PID)"
else
    echo "   ❌ Serveur a crashé"
    cat /tmp/lnurl-server.log
    exit 1
fi
echo ""

# Tester les endpoints
echo "4. Test des endpoints..."
RESPONSE=$(curl -s http://localhost:3000/request-channel)
if echo "$RESPONSE" | grep -q "uri"; then
    echo "   ✅ /request-channel fonctionne"
else
    echo "   ❌ /request-channel ne répond pas"
    echo "   Réponse: $RESPONSE"
fi

RESPONSE=$(curl -s http://localhost:3000/withdraw-request)
if echo "$RESPONSE" | grep -q "callback"; then
    echo "   ✅ /withdraw-request fonctionne"  
else
    echo "   ❌ /withdraw-request ne répond pas"
fi

RESPONSE=$(curl -s http://localhost:3000/auth)
if echo "$RESPONSE" | grep -q "k1"; then
    echo "   ✅ /auth fonctionne"
else
    echo "   ❌ /auth ne répond pas"
fi
echo ""

echo "================================================"
echo "  Infrastructure prête!"
echo "================================================"
echo ""
echo "Le serveur écoute sur http://localhost:3000"
echo ""
echo "Commandes utiles:"
echo "  - Voir les logs du serveur : tail -f /tmp/lnurl-server.log"
echo "  - Tester un endpoint : curl http://localhost:3000/request-channel"
echo "  - Arrêter tout : pkill lightningd ; pkill -f target/release/server"
echo ""
