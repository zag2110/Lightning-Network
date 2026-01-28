#!/bin/bash
# Script pour tester l'authentification LNURL avec le serveur du prof

SERVER_URL="http://82.67.177.113:3001"

echo "========================================="
echo "  Test LNURL Auth avec Serveur du Prof"
echo "========================================="
echo ""

# Étape 1 : Obtenir le challenge k1
echo "1. Récupération du challenge k1..."
RESPONSE=$(curl -s "$SERVER_URL/auth-challenge")
K1=$(echo "$RESPONSE" | jq -r '.k1')

if [ -z "$K1" ] || [ "$K1" = "null" ]; then
    echo "   ❌ Erreur : impossible de récupérer k1"
    echo "   Réponse : $RESPONSE"
    exit 1
fi

echo "   ✅ k1 reçu : $K1"
echo ""

# Étape 2 : Signer le message k1
echo "2. Signature du message avec Lightning..."
SIGN_RESPONSE=$(lightning-cli --network=testnet4 signmessage "$K1" 2>&1)

if echo "$SIGN_RESPONSE" | grep -q "error"; then
    echo "   ❌ Erreur de signature :"
    echo "$SIGN_RESPONSE"
    exit 1
fi

SIGNATURE=$(echo "$SIGN_RESPONSE" | jq -r '.signature')
RECID=$(echo "$SIGN_RESPONSE" | jq -r '.recid')
ZBASE=$(echo "$SIGN_RESPONSE" | jq -r '.zbase')

echo "   ✅ Message signé"
echo "   Signature: ${SIGNATURE:0:40}..."
echo "   RecID: $RECID"
echo "   Zbase: ${ZBASE:0:40}..."
echo ""

# Étape 3 : Récupérer la pubkey du nœud
echo "3. Récupération de la clé publique..."
PUBKEY=$(lightning-cli --network=testnet4 getinfo | jq -r '.id')
echo "   ✅ Pubkey : $PUBKEY"
echo ""

# Étape 4 : Appeler /auth-response avec signature (format attendu par le prof)
echo "4. Envoi de la réponse d'authentification..."
echo "   URL: $SERVER_URL/auth-response"
echo "   Paramètres: k1=$K1, signature=zbase, pubkey=$PUBKEY"
echo ""

# Test avec signature zbase (format compatible lnd)
AUTH_URL="$SERVER_URL/auth-response?k1=$K1&signature=$ZBASE&pubkey=$PUBKEY"
AUTH_RESPONSE=$(curl -s "$AUTH_URL")

echo "   Réponse du serveur :"
echo "$AUTH_RESPONSE" | jq . 2>/dev/null || echo "$AUTH_RESPONSE"
echo ""

# Vérifier le succès
if echo "$AUTH_RESPONSE" | grep -q '"status":"OK"' || echo "$AUTH_RESPONSE" | grep -q '"verified":true'; then
    echo "========================================="
    echo "  ✅ AUTHENTIFICATION RÉUSSIE !"
    echo "========================================="
    exit 0
else
    echo "========================================="
    echo "  ⚠️  Authentification échouée ou format inattendu"
    echo "========================================="
    echo ""
    echo "Essai avec signature hex brute..."
    AUTH_URL_HEX="$SERVER_URL/auth-response?k1=$K1&signature=$SIGNATURE&pubkey=$PUBKEY"
    AUTH_RESPONSE_HEX=$(curl -s "$AUTH_URL_HEX")
    echo "   Réponse :"
    echo "$AUTH_RESPONSE_HEX" | jq . 2>/dev/null || echo "$AUTH_RESPONSE_HEX"
    
    exit 1
fi
