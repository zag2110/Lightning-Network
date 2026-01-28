#!/bin/bash
# Script d'installation automatique LNURL Stack sur VPS Ubuntu
# Compatible : Ubuntu 22.04 LTS et 24.04 LTS
# Installe : Bitcoin Core (testnet4) + Core Lightning + Serveur LNURL

set -e

echo "================================================"
echo "  🚀 Installation LNURL Stack sur VPS"
echo "================================================"
echo ""
echo "Ce script va installer :"
echo "  - Bitcoin Core v30.2.0 (testnet4)"
echo "  - Core Lightning v25.12.1 (sans plugins Rust)"
echo "  - Serveur LNURL (port 3000)"
echo ""
read -p "Continuer ? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation annulée."
    exit 1
fi

# Variables de configuration
BITCOIN_VERSION="30.2.0"
BITCOIN_RPC_USER="lnurl_user"
BITCOIN_RPC_PASS="$(openssl rand -base64 32)"
LOG_FILE="$HOME/lnurl-install.log"

# Fonction de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Début de l'installation..."

# 1. Mise à jour du système
echo ""
echo "1️⃣  Mise à jour du système..."
log "Mise à jour du système"
sudo apt-get update -y >> "$LOG_FILE" 2>&1
sudo apt-get upgrade -y >> "$LOG_FILE" 2>&1
sudo apt-get install -y \
    curl wget git build-essential autoconf automake \
    libtool pkg-config libssl-dev libgmp-dev libsqlite3-dev \
    python3 python3-pip python3-mako zlib1g-dev gettext \
    jq screen ufw net-tools >> "$LOG_FILE" 2>&1
log "Système mis à jour"

# 2. Installation Rust
echo ""
echo "2️⃣  Installation de Rust..."
log "Installation Rust"
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1
    source $HOME/.cargo/env
    log "Rust installé : $(rustc --version)"
    echo "   ✅ Rust $(rustc --version | cut -d' ' -f2)"
else
    log "Rust déjà installé : $(rustc --version)"
    echo "   ✅ Rust déjà présent : $(rustc --version | cut -d' ' -f2)"
fi

# 3. Téléchargement Bitcoin Core
echo ""
echo "3️⃣  Téléchargement Bitcoin Core $BITCOIN_VERSION..."
log "Téléchargement Bitcoin Core $BITCOIN_VERSION"
cd $HOME
if [ ! -f "bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz" ]; then
    wget -q --show-progress https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz >> "$LOG_FILE" 2>&1
    log "Bitcoin Core téléchargé"
else
    log "Bitcoin Core déjà téléchargé"
    echo "   ℹ️  Archive déjà présente, extraction..."
fi

tar -xzf bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz >> "$LOG_FILE" 2>&1
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-$BITCOIN_VERSION/bin/* >> "$LOG_FILE" 2>&1
log "Bitcoin Core installé"
echo "   ✅ Bitcoin Core installé : $(bitcoind --version | head -1)"

# 4. Configuration Bitcoin Core
echo ""
echo "4️⃣  Configuration Bitcoin Core (testnet4)..."
log "Configuration Bitcoin Core"
mkdir -p $HOME/.bitcoin

cat > $HOME/.bitcoin/bitcoin.conf << EOF
# Bitcoin Core Configuration - Testnet4
testnet4=1
server=1
daemon=1
txindex=1

# RPC Configuration
rpcuser=$BITCOIN_RPC_USER
rpcpassword=$BITCOIN_RPC_PASS
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
rpcport=48332

# Network
listen=1
maxconnections=40

# Performance (optimisé pour VPS 2GB RAM)
dbcache=512
maxmempool=300
EOF

log "Bitcoin configuré"
echo "   ✅ Configuration créée"

# 5. Démarrage Bitcoin Core
echo ""
echo "5️⃣  Démarrage Bitcoin Core..."
log "Démarrage Bitcoin Core"
if pgrep -x bitcoind > /dev/null; then
    echo "   ⚠️  Bitcoin Core déjà en cours d'exécution"
    log "Bitcoin Core déjà actif"
else
    bitcoind -daemon >> "$LOG_FILE" 2>&1
    sleep 5
    log "Bitcoin Core démarré"
    echo "   ✅ Bitcoin Core démarré"
fi

# Attendre que Bitcoin RPC soit prêt
echo "   ⏳ Attente du démarrage RPC..."
for i in {1..30}; do
    if bitcoin-cli -testnet4 getblockcount &> /dev/null; then
        BLOCKS=$(bitcoin-cli -testnet4 getblockcount)
        echo "   ✅ RPC actif - Blocks: $BLOCKS"
        log "Bitcoin RPC actif - Blocks: $BLOCKS"
        break
    fi
    sleep 2
done

# 6. Création du wallet
echo ""
echo "6️⃣  Création du wallet Bitcoin..."
log "Création wallet"
sleep 5
if bitcoin-cli -testnet4 createwallet "lnurl_wallet" >> "$LOG_FILE" 2>&1; then
    log "Wallet créé"
    echo "   ✅ Wallet créé"
else
    log "Wallet existe déjà"
    echo "   ℹ️  Wallet existe déjà"
fi

WALLET_ADDRESS=$(bitcoin-cli -testnet4 -rpcwallet=lnurl_wallet getnewaddress "Faucet" "bech32")
log "Adresse wallet : $WALLET_ADDRESS"
echo "   📍 Adresse : $WALLET_ADDRESS"
echo ""
echo "   ⚠️  IMPORTANT : Obtenir des testnet4 coins :"
echo "      https://mempool.space/testnet4/faucet"
echo "      Envoyer à : $WALLET_ADDRESS"

# 7. Compilation Core Lightning
echo ""
echo "7️⃣  Compilation Core Lightning v25.12.1..."
log "Début compilation CLN"
cd $HOME

if [ ! -d "lightning" ]; then
    log "Clonage repo CLN"
    git clone https://github.com/ElementsProject/lightning.git >> "$LOG_FILE" 2>&1
fi

cd lightning
git fetch --tags >> "$LOG_FILE" 2>&1
git checkout v25.12.1 >> "$LOG_FILE" 2>&1
log "CLN v25.12.1 checked out"

echo "   ⏳ Configuration (--disable-rust pour stabilité)..."
./configure --disable-rust >> "$LOG_FILE" 2>&1
log "CLN configuré"

echo "   ⏳ Compilation (peut prendre 5-10 minutes)..."
make -j$(nproc) >> "$LOG_FILE" 2>&1
log "CLN compilé"

echo "   ⏳ Installation..."
sudo make install >> "$LOG_FILE" 2>&1
log "CLN installé"
echo "   ✅ Core Lightning installé : $(lightningd --version | head -1)"

# 8. Configuration Core Lightning
echo ""
echo "8️⃣  Configuration Core Lightning..."
log "Configuration CLN"
mkdir -p $HOME/.lightning

cat > $HOME/.lightning/config << EOF
network=testnet4
log-file=$HOME/.lightning/testnet4/lightning.log
log-level=info
bitcoin-rpcuser=$BITCOIN_RPC_USER
bitcoin-rpcpassword=$BITCOIN_RPC_PASS
bitcoin-rpcconnect=127.0.0.1
bitcoin-rpcport=48332
# Désactiver les plugins Rust (compilés avec --disable-rust)
disable-plugin=spenderp
disable-plugin=bookkeeper
EOF

log "CLN configuré"
echo "   ✅ Configuration créée"

# 9. Attente synchronisation Bitcoin
echo ""
echo "9️⃣  Synchronisation Bitcoin (peut prendre 30-60 min)..."
echo "   ℹ️  Vous pouvez surveiller dans un autre terminal avec :"
echo "      watch -n 10 'bitcoin-cli -testnet4 getblockchaininfo | jq \".blocks, .initialblockdownload\"'"
echo ""
log "Attente sync Bitcoin"

SYNC_START=$(date +%s)
while true; do
    BLOCKS=$(bitcoin-cli -testnet4 getblockcount 2>/dev/null || echo "0")
    IBD=$(bitcoin-cli -testnet4 getblockchaininfo 2>/dev/null | jq -r '.initialblockdownload' || echo "true")
    ELAPSED=$(($(date +%s) - SYNC_START))
    
    echo -ne "   ⏳ Blocks: $BLOCKS | IBD: $IBD | Temps: ${ELAPSED}s\r"
    
    if [ "$IBD" = "false" ]; then
        echo ""
        echo "   ✅ Synchronisation terminée ! ($BLOCKS blocs)"
        log "Bitcoin synced - $BLOCKS blocs"
        break
    fi
    sleep 30
done

# 10. Démarrage Core Lightning
echo ""
echo "🔟 Démarrage Core Lightning..."
log "Démarrage CLN"

if pgrep -x lightningd > /dev/null; then
    echo "   ⚠️  Lightning déjà en cours d'exécution"
    log "Lightning déjà actif"
else
    lightningd --network=testnet4 --daemon >> "$LOG_FILE" 2>&1
    sleep 10
    log "Lightning démarré"
fi

# Attendre que Lightning RPC soit prêt
echo "   ⏳ Attente du démarrage Lightning RPC..."
for i in {1..20}; do
    if lightning-cli --network=testnet4 getinfo &> /dev/null; then
        NODE_ID=$(lightning-cli --network=testnet4 getinfo | jq -r '.id')
        NODE_ALIAS=$(lightning-cli --network=testnet4 getinfo | jq -r '.alias')
        echo "   ✅ Lightning actif"
        echo "   📍 Node ID : $NODE_ID"
        echo "   🏷️  Alias : $NODE_ALIAS"
        log "Lightning actif - ID: $NODE_ID"
        break
    fi
    sleep 3
done

# 11. Vérifier présence du code LNURL
echo ""
echo "1️⃣1️⃣  Vérification du code LNURL..."
log "Vérification code LNURL"

if [ ! -d "$HOME/lnurl-project" ]; then
    echo "   ⚠️  Code LNURL non trouvé dans $HOME/lnurl-project"
    echo ""
    echo "   📋 Options pour copier le code :"
    echo ""
    echo "   Option A - Via Git (recommandé) :"
    echo "      # Sur ton PC WSL :"
    echo "      cd '/mnt/c/Sacha/Cours/LN version 2'"
    echo "      git init"
    echo "      git add lnurl-client/ lnurl-server/"
    echo "      git commit -m 'Initial commit'"
    echo "      git remote add origin <URL_GITHUB_PRIVÉ>"
    echo "      git push -u origin main"
    echo ""
    echo "      # Sur le VPS :"
    echo "      git clone <URL_GITHUB_PRIVÉ> $HOME/lnurl-project"
    echo ""
    echo "   Option B - Via SCP :"
    echo "      # Sur ton PC WSL :"
    echo "      cd '/mnt/c/Sacha/Cours/LN version 2'"
    echo "      scp -r lnurl-client lnurl-server $(whoami)@$(curl -s ifconfig.me):~/lnurl-project/"
    echo ""
    echo "   Après avoir copié le code, relancez ce script ou passez à l'étape suivante manuellement."
    log "Code LNURL non trouvé - instructions affichées"
    
    read -p "   Voulez-vous que le script attende que vous copiez le code ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   ⏳ En attente du code dans $HOME/lnurl-project..."
        while [ ! -d "$HOME/lnurl-project/lnurl-server" ]; do
            sleep 5
            echo -ne "   ⏳ Vérification...\r"
        done
        echo ""
        echo "   ✅ Code détecté !"
        log "Code LNURL copié"
    else
        echo ""
        echo "   ⚠️  Installation partiellement terminée."
        echo "      Après avoir copié le code, compilez le serveur avec :"
        echo "      cd $HOME/lnurl-project/lnurl-server && cargo build --release"
        log "Installation partielle - en attente du code"
        exit 0
    fi
fi

# 12. Compilation du serveur LNURL
echo ""
echo "1️⃣2️⃣  Compilation du serveur LNURL..."
log "Compilation serveur LNURL"

cd $HOME/lnurl-project/lnurl-server
source $HOME/.cargo/env
cargo build --release >> "$LOG_FILE" 2>&1
log "Serveur LNURL compilé"
echo "   ✅ Serveur compilé : $HOME/lnurl-project/lnurl-server/target/release/server"

# 13. Configuration du firewall
echo ""
echo "1️⃣3️⃣  Configuration du firewall UFW..."
log "Configuration firewall"

sudo ufw --force disable >> "$LOG_FILE" 2>&1
sudo ufw --force reset >> "$LOG_FILE" 2>&1

# Règles basiques
sudo ufw default deny incoming >> "$LOG_FILE" 2>&1
sudo ufw default allow outgoing >> "$LOG_FILE" 2>&1

# Ports autorisés
sudo ufw allow 22/tcp comment 'SSH' >> "$LOG_FILE" 2>&1
sudo ufw allow 3000/tcp comment 'LNURL Server' >> "$LOG_FILE" 2>&1
sudo ufw allow 48333/tcp comment 'Bitcoin P2P testnet4' >> "$LOG_FILE" 2>&1
sudo ufw allow 19846/tcp comment 'Lightning P2P testnet4' >> "$LOG_FILE" 2>&1

sudo ufw --force enable >> "$LOG_FILE" 2>&1
log "Firewall configuré"
echo "   ✅ Firewall configuré :"
echo "      - SSH (22)"
echo "      - LNURL (3000)"
echo "      - Bitcoin P2P (48333)"
echo "      - Lightning P2P (19846)"

# 14. Création du service systemd
echo ""
echo "1️⃣4️⃣  Création du service systemd..."
log "Création service systemd"

sudo tee /etc/systemd/system/lnurl-server.service > /dev/null << EOF
[Unit]
Description=LNURL Server
After=network.target bitcoin.service lightning.service
Requires=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/lnurl-project/lnurl-server
ExecStart=$HOME/lnurl-project/lnurl-server/target/release/server
Restart=always
RestartSec=10
StandardOutput=append:$HOME/lnurl-server.log
StandardError=append:$HOME/lnurl-server-error.log

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
sudo systemctl enable lnurl-server >> "$LOG_FILE" 2>&1
sudo systemctl start lnurl-server >> "$LOG_FILE" 2>&1
log "Service systemd créé et démarré"
echo "   ✅ Service systemd créé et démarré"
sleep 3

# Vérifier que le serveur tourne
if sudo systemctl is-active --quiet lnurl-server; then
    echo "   ✅ Serveur LNURL actif"
    log "Serveur LNURL actif"
else
    echo "   ⚠️  Serveur LNURL non actif - vérifier les logs :"
    echo "      sudo journalctl -u lnurl-server -n 50"
    log "Serveur LNURL non actif"
fi

# 15. Sauvegarder les informations
echo ""
echo "1️⃣5️⃣  Sauvegarde des informations..."
log "Sauvegarde infos"

PUBLIC_IP=$(curl -s ifconfig.me)

cat > $HOME/lnurl-info.txt << EOF
================================================
  LNURL Stack - Informations de Configuration
================================================

Date d'installation : $(date)

🔐 Bitcoin Core
---------------
RPC User     : $BITCOIN_RPC_USER
RPC Password : $BITCOIN_RPC_PASS
RPC Port     : 48332
Wallet Name  : lnurl_wallet
Wallet Addr  : $WALLET_ADDRESS

⚡ Core Lightning
----------------
Node ID      : $NODE_ID
Node Alias   : $NODE_ALIAS
RPC Socket   : $HOME/.lightning/testnet4/lightning-rpc

🌐 Serveur LNURL
----------------
Port interne : 3000
IP publique  : $PUBLIC_IP
URL externe  : http://$PUBLIC_IP:3000

📡 Endpoints disponibles :
- http://$PUBLIC_IP:3000/request-channel
- http://$PUBLIC_IP:3000/open-channel
- http://$PUBLIC_IP:3000/withdraw-request
- http://$PUBLIC_IP:3000/withdraw
- http://$PUBLIC_IP:3000/auth
- http://$PUBLIC_IP:3000/auth-verify

📝 Commandes Utiles
-------------------
# Bitcoin
bitcoin-cli -testnet4 getblockchaininfo
bitcoin-cli -testnet4 -rpcwallet=lnurl_wallet getbalance

# Lightning
lightning-cli --network=testnet4 getinfo
lightning-cli --network=testnet4 listfunds
lightning-cli --network=testnet4 fundchannel <node_id> <amount_sats>

# Serveur LNURL
sudo systemctl status lnurl-server
sudo systemctl restart lnurl-server
sudo journalctl -u lnurl-server -f

# Logs
tail -f $HOME/.lightning/testnet4/lightning.log
tail -f $HOME/lnurl-server.log

⚠️  À FAIRE
-----------
1. Envoyer des testnet4 coins à : $WALLET_ADDRESS
   Faucet : https://mempool.space/testnet4/faucet

2. Attendre les confirmations (6+ blocs)

3. Tester les endpoints :
   curl http://$PUBLIC_IP:3000/request-channel

4. Informer le professeur de l'IP publique : $PUBLIC_IP

💾 IMPORTANT
------------
Ce fichier contient des informations sensibles.
Sauvegardez-le dans un endroit sûr et supprimez-le du serveur après lecture :
  rm $HOME/lnurl-info.txt

================================================
EOF

log "Informations sauvegardées dans $HOME/lnurl-info.txt"

# Affichage final
echo ""
echo "================================================"
echo "  ✅ Installation Terminée avec Succès !"
echo "================================================"
echo ""
cat $HOME/lnurl-info.txt
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Lire et sauvegarder : cat $HOME/lnurl-info.txt"
echo "   2. Obtenir des testcoins : https://mempool.space/testnet4/faucet"
echo "   3. Tester : curl http://$PUBLIC_IP:3000/request-channel"
echo "   4. Informer le prof de l'IP : $PUBLIC_IP"
echo ""
echo "📊 Logs d'installation : $LOG_FILE"
echo ""
log "Installation terminée avec succès"

exit 0
