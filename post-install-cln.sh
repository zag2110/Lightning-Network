#!/bin/bash
# Script post-compilation pour configurer Core Lightning avec testnet4

echo "========================================="
echo "Configuration post-compilation"
echo "Core Lightning avec testnet4"
echo "========================================="
echo ""

# 1. Vérifier que lightningd existe
if ! command -v lightningd &> /dev/null; then
    echo "❌ lightningd non installé"
    echo "Lancez d'abord : sudo make install depuis ~/lightning"
    exit 1
fi

echo "✓ lightningd installé : $(lightningd --version | head -1)"

# 2. Vérifier le support testnet4
echo ""
echo "Vérification du support testnet4..."
if lightningd --help | grep -q "testnet4"; then
    echo "✓ testnet4 supporté !"
else
    echo "❌ testnet4 non supporté - version trop ancienne"
    exit 1
fi

# 3. Mettre à jour la configuration
echo ""
echo "Mise à jour de ~/.lightning/config..."

cat > ~/.lightning/config << 'EOF'
# Configuration Core Lightning pour testnet4
network=testnet4
log-level=info
log-file=/tmp/lightningd.log

# Bitcoin Core RPC
bitcoin-rpcuser=lnurl_user
bitcoin-rpcpassword=ChangeMeToSecurePassword123
bitcoin-rpcport=48332

# Réseau
bind-addr=0.0.0.0:49735
announce-addr=127.0.0.1:49735

# Plugin désactivé
disable-plugin=/usr/local/libexec/c-lightning/plugins/clnrest/clnrest.py
EOF

echo "✓ Configuration mise à jour"

# 4. Mettre à jour le chemin RPC dans le client
echo ""
echo "Mise à jour du client lnurl..."

CLIENT_FILE=~/LN_version_2/lnurl-client/src/main.rs
if [ -f "$CLIENT_FILE" ]; then
    CURRENT_USER=$(whoami)
    sed -i "s|/home/sosthene/.lightning/testnet4|/home/$CURRENT_USER/.lightning/testnet4|g" "$CLIENT_FILE"
    sed -i "s|/home/$CURRENT_USER/.lightning/testnet|/home/$CURRENT_USER/.lightning/testnet4|g" "$CLIENT_FILE"
    echo "✓ Client mis à jour pour l'utilisateur: $CURRENT_USER"
    
    # Recompiler le client
    echo ""
    echo "Recompilation du client..."
    cd ~/LN_version_2/lnurl-client
    cargo build --release
    echo "✓ Client recompilé"
else
    echo "⚠ Fichier client non trouvé : $CLIENT_FILE"
fi

# 5. Instructions finales
echo ""
echo "========================================="
echo "✓ Configuration terminée!"
echo "========================================="
echo ""
echo "Prochaines étapes:"
echo ""
echo "1. Vérifier que Bitcoin Core tourne :"
echo "   bitcoin-cli -testnet4 getblockchaininfo"
echo ""
echo "2. Démarrer Core Lightning :"
echo "   lightningd --network=testnet4 --daemon"
echo ""
echo "3. Vérifier Lightning :"
echo "   sleep 3"
echo "   lightning-cli --network=testnet4 getinfo"
echo ""
echo "4. Tester le client complet :"
echo "   cd ~/LN_version_2/lnurl-client"
echo "   cargo run --release -- request-channel 82.67.177.113:3001"
echo ""
