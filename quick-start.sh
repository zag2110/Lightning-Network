#!/bin/bash
# Script de démarrage rapide - à exécuter JUSTE AVANT le test
# Lightning reste stable ~20-30 secondes

echo "================================================"
echo "  DÉMARRAGE RAPIDE (Just-In-Time)"
echo "================================================"
echo ""

# Nettoyer tout
pkill -9 lightningd 2>/dev/null
pkill -f "target/release/server" 2>/dev/null
rm -f ~/.lightning/testnet4/lightning-rpc ~/.lightning/testnet4/.lock
sleep 2

# Démarrer Lightning
echo "Démarrage Lightning..."
lightningd --network=testnet4 > /tmp/lightning.log 2>&1 &
LPID=$!
echo "  Lightning PID: $LPID"
echo "  Attente 8 secondes..."
sleep 8

# Vérifier Lightning
if lightning-cli --network=testnet4 getinfo > /dev/null 2>&1; then
    echo "  ✅ Lightning répond"
else
    echo "  ❌ Lightning ne répond pas"
    exit 1
fi

# Démarrer serveur IMMÉDIATEMENT
echo ""
echo "Démarrage serveur LNURL..."
cd ~/LN_version_2/lnurl-server
./target/release/server > /tmp/server.log 2>&1 &
SPID=$!
echo "  Serveur PID: $SPID"
echo "  Attente 3 secondes..."
sleep 3

# Vérifier serveur
if ps -p $SPID > /dev/null 2>&1; then
    echo "  ✅ Serveur actif"
else
    echo "  ❌ Serveur crashed"
    cat /tmp/server.log
    exit 1
fi

echo ""
echo "================================================"
echo "  Infrastructure prête! (stable ~20 secondes)"
echo "================================================"
echo ""

# Test rapide
echo "Test endpoints..."
echo ""
echo "1. /request-channel:"
curl -s http://localhost:3000/request-channel | head -c 200
echo "..."
echo ""

echo "2. /withdraw-request:"
curl -s http://localhost:3000/withdraw-request | head -c 200
echo "..."
echo ""

echo "3. /auth:"
curl -s http://localhost:3000/auth | head -c 200
echo "..."
echo ""

echo "================================================"
echo "  Prêt pour test du professeur!"
echo "================================================"
echo ""
echo "Commandes pour le prof:"
echo "  curl http://localhost:3000/request-channel"
echo "  curl http://localhost:3000/withdraw-request"
echo "  curl http://localhost:3000/auth"
echo ""
echo "NOTE: Lightning/Serveur stables pendant ~20-30s"
echo "      Relancer ce script si nécessaire"
echo ""
