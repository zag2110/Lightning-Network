#!/bin/bash
# Script d'installation automatique de Bitcoin Core et Core Lightning pour testnet4

set -e  # Arrêter en cas d'erreur

echo "========================================="
echo "Installation Bitcoin Core + Core Lightning"
echo "Pour testnet4"
echo "========================================="
echo ""

# Couleurs pour l'affichage
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Vérifier qu'on est bien sous Linux/WSL
if [[ ! -f /proc/version ]]; then
    echo "Ce script doit être exécuté sous Linux/WSL"
    exit 1
fi

# 1. INSTALLATION DE BITCOIN CORE
echo ""
echo "========================================="
echo "1. Installation de Bitcoin Core"
echo "========================================="

BITCOIN_VERSION="27.0"
BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz"

if command -v bitcoind &> /dev/null; then
    log_info "Bitcoin Core est déjà installé ($(bitcoind --version | head -n1))"
else
    log_info "Téléchargement de Bitcoin Core ${BITCOIN_VERSION}..."
    cd ~
    wget -q --show-progress "$BITCOIN_URL"
    
    log_info "Extraction..."
    tar -xzf "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz"
    
    log_info "Installation..."
    sudo install -m 0755 -o root -g root -t /usr/local/bin "bitcoin-${BITCOIN_VERSION}/bin/"*
    
    log_info "Nettoyage..."
    rm -rf "bitcoin-${BITCOIN_VERSION}" "bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz"
    
    log_info "✓ Bitcoin Core installé avec succès"
fi

# 2. CONFIGURATION DE BITCOIN CORE
echo ""
echo "========================================="
echo "2. Configuration de Bitcoin Core"
echo "========================================="

mkdir -p ~/.bitcoin

if [[ ! -f ~/.bitcoin/bitcoin.conf ]]; then
    log_info "Création du fichier de configuration..."
    cat > ~/.bitcoin/bitcoin.conf << 'EOF'
# Configuration Bitcoin Core pour testnet4
testnet4=1
server=1
daemon=1
txindex=1

# RPC
rpcuser=lightninguser
rpcpassword=lightningpassword123
rpcport=48332

# Performance
dbcache=512
maxmempool=300

# Réseau
listen=1
discover=1
EOF
    log_info "✓ Configuration créée : ~/.bitcoin/bitcoin.conf"
else
    log_warn "Le fichier de configuration existe déjà : ~/.bitcoin/bitcoin.conf"
fi

# 3. INSTALLATION DES DÉPENDANCES POUR CLN
echo ""
echo "========================================="
echo "3. Installation des dépendances"
echo "========================================="

log_info "Mise à jour des paquets..."
sudo apt update -qq

log_info "Installation des dépendances pour Core Lightning..."
sudo apt install -y -qq \
    autoconf automake build-essential git libtool libsqlite3-dev \
    python3 python3-pip net-tools zlib1g-dev libsodium-dev gettext \
    libgmp-dev libssl-dev

log_info "✓ Dépendances installées"

# 4. INSTALLATION DE CORE LIGHTNING
echo ""
echo "========================================="
echo "4. Installation de Core Lightning"
echo "========================================="

CLN_DIR=~/lightning

if [[ -d "$CLN_DIR" ]]; then
    log_warn "Le répertoire $CLN_DIR existe déjà"
    read -p "Voulez-vous le mettre à jour ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Mise à jour de Core Lightning..."
        cd "$CLN_DIR"
        git pull
    else
        log_info "Utilisation de l'installation existante"
        cd "$CLN_DIR"
    fi
else
    log_info "Clonage de Core Lightning..."
    git clone https://github.com/ElementsProject/lightning.git "$CLN_DIR"
    cd "$CLN_DIR"
fi

log_info "Checkout de la dernière version stable..."
git fetch --tags
LATEST_TAG=$(git describe --tags --abbrev=0)
git checkout "$LATEST_TAG"

log_info "Installation de Poetry..."
pip3 install --user poetry --quiet

log_info "Installation des dépendances Python..."
~/.local/bin/poetry install --quiet

log_info "Configuration..."
./configure --enable-developer

log_info "Compilation (cela peut prendre plusieurs minutes)..."
~/.local/bin/poetry run make -j$(nproc)

log_info "Installation..."
sudo make install

log_info "✓ Core Lightning installé avec succès"

# 5. CONFIGURATION DE CORE LIGHTNING
echo ""
echo "========================================="
echo "5. Configuration de Core Lightning"
echo "========================================="

mkdir -p ~/.lightning

if [[ ! -f ~/.lightning/config ]]; then
    log_info "Création du fichier de configuration..."
    cat > ~/.lightning/config << 'EOF'
# Configuration Core Lightning pour testnet4
network=testnet4
log-level=info
log-file=/tmp/lightningd.log

# Bitcoin Core RPC
bitcoin-rpcuser=lightninguser
bitcoin-rpcpassword=lightningpassword123
bitcoin-rpcport=48332

# Réseau
bind-addr=0.0.0.0:49735
announce-addr=127.0.0.1:49735
EOF
    log_info "✓ Configuration créée : ~/.lightning/config"
else
    log_warn "Le fichier de configuration existe déjà : ~/.lightning/config"
fi

# 6. MODIFICATION DU CLIENT LNURL
echo ""
echo "========================================="
echo "6. Configuration du client LNURL"
echo "========================================="

CLIENT_FILE=~/LN_version_2/lnurl-client/src/main.rs
CURRENT_USER=$(whoami)

if [[ -f "$CLIENT_FILE" ]]; then
    log_info "Mise à jour du chemin RPC dans le client..."
    
    # Remplacer le chemin de l'utilisateur sosthene par l'utilisateur actuel
    sed -i "s|/home/sosthene/.lightning|/home/$CURRENT_USER/.lightning|g" "$CLIENT_FILE"
    
    log_info "✓ Chemin RPC mis à jour pour l'utilisateur : $CURRENT_USER"
    
    # Recompiler le client
    log_info "Recompilation du client..."
    cd ~/LN_version_2/lnurl-client
    cargo build --release
    log_info "✓ Client recompilé"
else
    log_warn "Fichier client non trouvé : $CLIENT_FILE"
fi

# 7. RÉCAPITULATIF
echo ""
echo "========================================="
echo "✓ INSTALLATION TERMINÉE !"
echo "========================================="
echo ""
echo "Prochaines étapes :"
echo ""
echo "1. Démarrer Bitcoin Core :"
echo "   bitcoind -testnet4"
echo ""
echo "2. Attendre la synchronisation (vérifier avec) :"
echo "   bitcoin-cli -testnet4 getblockchaininfo"
echo ""
echo "3. Démarrer Core Lightning :"
echo "   lightningd --network=testnet4"
echo ""
echo "4. Vérifier le nœud Lightning :"
echo "   lightning-cli --network=testnet4 getinfo"
echo ""
echo "5. Tester le client LNURL :"
echo "   cd ~/LN_version_2/lnurl-client"
echo "   cargo run --release -- request-channel 82.67.177.113:3001"
echo ""
echo "Fichiers de configuration :"
echo "  - Bitcoin : ~/.bitcoin/bitcoin.conf"
echo "  - Lightning : ~/.lightning/config"
echo ""
echo "Logs :"
echo "  - Bitcoin : ~/.bitcoin/testnet4/debug.log"
echo "  - Lightning : /tmp/lightningd.log"
echo ""
