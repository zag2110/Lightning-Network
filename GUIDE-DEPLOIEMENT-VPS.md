# Guide Déploiement VPS - Projet LNURL

**Objectif :** Déployer Bitcoin Core + Core Lightning + Serveur LNURL sur un VPS Linux pour résoudre le problème de stabilité WSL.

---

## 🎯 Pourquoi un VPS ?

### Avantages
✅ **Linux natif** → Plus de problème de plugins Lightning  
✅ **Disponible 24/7** → Le prof peut tester quand il veut  
✅ **IP publique** → Pas de configuration réseau complexe  
✅ **Performance** → Meilleure que WSL  
✅ **Utile pour la carrière** → Compétence DevOps valorisée

### Coût
💰 **4-6€/mois** pour un VPS adapté (moins qu'un café à Paris !)

---

## 📋 Choix du VPS

### Providers Recommandés (Budget Étudiant)

#### 1. Hetzner Cloud (Recommandé) 🥇
- **Prix :** 4.51€/mois (CPX11)
- **Specs :** 2 vCPU, 2 GB RAM, 40 GB SSD
- **Datacenter :** Allemagne/Finlande
- **Avantages :** Excellent rapport qualité/prix, réseau rapide
- **Lien :** https://www.hetzner.com/cloud

#### 2. Contabo
- **Prix :** 4.99€/mois (Cloud VPS S)
- **Specs :** 4 vCPU, 6 GB RAM, 100 GB SSD
- **Avantages :** Plus de ressources pour le prix
- **Lien :** https://contabo.com/en/vps/

#### 3. DigitalOcean
- **Prix :** 6$/mois (Basic Droplet)
- **Specs :** 1 vCPU, 1 GB RAM, 25 GB SSD
- **Avantages :** Interface simple, documentation excellente
- **Bonus :** 200$ de crédit gratuit avec GitHub Student Pack
- **Lien :** https://www.digitalocean.com/

#### 4. Oracle Cloud (GRATUIT)
- **Prix :** 0€ (Free Tier permanent)
- **Specs :** 1 vCPU, 1 GB RAM, 50 GB
- **Avantages :** Gratuit à vie !
- **Inconvénient :** Configuration plus complexe
- **Lien :** https://www.oracle.com/cloud/free/

### Recommandation

**Pour ce projet :** Hetzner Cloud CPX11 (4.51€/mois)
- Assez puissant pour Bitcoin testnet4 + Lightning
- Réseau rapide
- Interface simple
- Bon support

---

## 🚀 Installation Automatisée

### Script d'Installation Complet

J'ai créé un script qui installe TOUT automatiquement sur un VPS Ubuntu fresh :

**Fichier :** `deploy-vps.sh`

```bash
#!/bin/bash
# Script d'installation automatique pour VPS Ubuntu 22.04/24.04
# Installe : Bitcoin Core (testnet4) + Core Lightning + Serveur LNURL

set -e

echo "================================================"
echo "  Installation LNURL Stack sur VPS"
echo "================================================"
echo ""

# Variables de configuration
BITCOIN_VERSION="30.2.0"
BITCOIN_RPC_USER="lnurl_user"
BITCOIN_RPC_PASS="$(openssl rand -base64 32)"

echo "1. Mise à jour du système..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git build-essential autoconf automake \
    libtool pkg-config libssl-dev libgmp-dev libsqlite3-dev python3 \
    python3-pip zlib1g-dev jq screen ufw

echo ""
echo "2. Installation Rust..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo "Rust installé : $(rustc --version)"
else
    echo "Rust déjà installé : $(rustc --version)"
fi

echo ""
echo "3. Téléchargement Bitcoin Core $BITCOIN_VERSION..."
cd $HOME
wget https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz
tar -xzf bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-$BITCOIN_VERSION/bin/*

echo ""
echo "4. Configuration Bitcoin Core (testnet4)..."
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

# Performance
dbcache=512
maxmempool=300
EOF

echo ""
echo "5. Démarrage Bitcoin Core..."
bitcoind -daemon
sleep 5
echo "Bitcoin Core démarré. Synchronisation en cours..."
echo "Blocks actuels : $(bitcoin-cli -testnet4 getblockcount 2>/dev/null || echo 'En attente...')"

echo ""
echo "6. Création du wallet..."
sleep 10
bitcoin-cli -testnet4 createwallet "lnurl_wallet" || echo "Wallet existe déjà"
WALLET_ADDRESS=$(bitcoin-cli -testnet4 -rpcwallet=lnurl_wallet getnewaddress "Faucet" "bech32")
echo "Adresse du wallet : $WALLET_ADDRESS"
echo ""
echo "⚠️  IMPORTANT : Envoyer des testnet4 coins à cette adresse :"
echo "    $WALLET_ADDRESS"
echo "    Faucet : https://mempool.space/testnet4/faucet"

echo ""
echo "7. Compilation Core Lightning..."
cd $HOME
git clone https://github.com/ElementsProject/lightning.git
cd lightning
git checkout v25.12.1
./configure --disable-rust
make -j$(nproc)
sudo make install

echo ""
echo "8. Configuration Core Lightning..."
mkdir -p $HOME/.lightning
cat > $HOME/.lightning/config << EOF
network=testnet4
log-file=$HOME/.lightning/testnet4/lightning.log
log-level=info
bitcoin-rpcuser=$BITCOIN_RPC_USER
bitcoin-rpcpassword=$BITCOIN_RPC_PASS
bitcoin-rpcconnect=127.0.0.1
bitcoin-rpcport=48332
# Désactiver les plugins Rust problématiques
disable-plugin=spenderp
disable-plugin=bookkeeper
EOF

echo ""
echo "9. Attente synchronisation Bitcoin (peut prendre 30-60 min)..."
echo "   Vous pouvez surveiller avec : bitcoin-cli -testnet4 getblockchaininfo"
while true; do
    BLOCKS=$(bitcoin-cli -testnet4 getblockcount 2>/dev/null || echo "0")
    IBD=$(bitcoin-cli -testnet4 getblockchaininfo 2>/dev/null | jq -r '.initialblockdownload')
    echo "   Blocks: $BLOCKS | Initial sync: $IBD"
    if [ "$IBD" = "false" ]; then
        echo "   ✅ Synchronisation terminée !"
        break
    fi
    sleep 60
done

echo ""
echo "10. Démarrage Core Lightning..."
lightningd --network=testnet4 --daemon
sleep 10
NODE_ID=$(lightning-cli --network=testnet4 getinfo | jq -r '.id')
echo "Lightning Node ID : $NODE_ID"

echo ""
echo "11. Clonage du code LNURL..."
cd $HOME
git clone <URL_DE_TON_REPO> lnurl-project || echo "Repo déjà cloné"
# Ou copier les fichiers depuis WSL

echo ""
echo "12. Compilation du serveur LNURL..."
cd $HOME/lnurl-project/lnurl-server
cargo build --release

echo ""
echo "13. Configuration du firewall..."
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 3000/tcp    # Serveur LNURL
sudo ufw allow 48333/tcp   # Bitcoin P2P (testnet4)
sudo ufw allow 19846/tcp   # Lightning P2P (testnet4)
sudo ufw --force enable

echo ""
echo "14. Création du service systemd..."
sudo tee /etc/systemd/system/lnurl-server.service > /dev/null << EOF
[Unit]
Description=LNURL Server
After=network.target lightningd.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/lnurl-project/lnurl-server
ExecStart=$HOME/lnurl-project/lnurl-server/target/release/server
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable lnurl-server
sudo systemctl start lnurl-server

echo ""
echo "================================================"
echo "  Installation Terminée !"
echo "================================================"
echo ""
echo "📊 Informations importantes :"
echo ""
echo "Bitcoin RPC User     : $BITCOIN_RPC_USER"
echo "Bitcoin RPC Password : $BITCOIN_RPC_PASS"
echo "Wallet Address       : $WALLET_ADDRESS"
echo "Lightning Node ID    : $NODE_ID"
echo ""
echo "🌐 Accès externe :"
echo "   IP du VPS : $(curl -s ifconfig.me)"
echo "   Serveur LNURL : http://$(curl -s ifconfig.me):3000"
echo ""
echo "📝 Commandes utiles :"
echo "   bitcoin-cli -testnet4 getblockchaininfo"
echo "   lightning-cli --network=testnet4 getinfo"
echo "   sudo systemctl status lnurl-server"
echo "   sudo journalctl -u lnurl-server -f"
echo ""
echo "⚠️  N'oubliez pas :"
echo "   1. Envoyer des coins à : $WALLET_ADDRESS"
echo "   2. Attendre quelques confirmations"
echo "   3. Tester : curl http://$(curl -s ifconfig.me):3000/request-channel"
echo ""
echo "💾 Sauvegardez ces informations dans un endroit sûr !"
echo ""
```

---

## 📝 Procédure de Déploiement

### Étape 1 : Créer le VPS

1. **Choisir un provider** (recommandé : Hetzner Cloud)
2. **Créer un compte**
3. **Créer un VPS** :
   - OS : **Ubuntu 24.04 LTS** (ou 22.04)
   - Plan : **CPX11** ou équivalent (2 vCPU, 2 GB RAM minimum)
   - Datacenter : Au choix (Allemagne recommandé)
   - SSH Key : Générer ou uploader ta clé publique

4. **Noter l'IP publique** du VPS

### Étape 2 : Connexion SSH

```bash
# Depuis WSL ou PowerShell
ssh root@<IP_DU_VPS>
```

### Étape 3 : Copier les Fichiers

**Option A : Via Git (Recommandé)**
```bash
# Sur ton PC, créer un repo GitHub privé avec ton code
cd "/mnt/c/Sacha/Cours/LN version 2"
git init
git add lnurl-client/ lnurl-server/
git commit -m "Initial commit"
git remote add origin <URL_GITHUB>
git push -u origin main

# Sur le VPS
git clone <URL_GITHUB> lnurl-project
```

**Option B : Via SCP**
```bash
# Depuis WSL
cd "/mnt/c/Sacha/Cours/LN version 2"
scp -r lnurl-client lnurl-server root@<IP_VPS>:~/
```

### Étape 4 : Lancer le Script d'Installation

```bash
# Sur le VPS
cd ~
curl -O <URL_DU_SCRIPT>/deploy-vps.sh
chmod +x deploy-vps.sh
./deploy-vps.sh
```

Le script va :
- ✅ Installer toutes les dépendances
- ✅ Télécharger et configurer Bitcoin Core
- ✅ Compiler Core Lightning (avec `--disable-rust` pour stabilité)
- ✅ Configurer le firewall
- ✅ Compiler ton serveur LNURL
- ✅ Créer un service systemd qui démarre automatiquement

### Étape 5 : Obtenir des Testcoins

```bash
# Le script affiche l'adresse du wallet
# Aller sur : https://mempool.space/testnet4/faucet
# Envoyer des testnet4 coins à ton adresse
```

### Étape 6 : Ouvrir un Canal avec le Prof

```bash
# Une fois les coins reçus et confirmés
lightning-cli --network=testnet4 fundchannel <NODE_ID_PROF> 100000
```

### Étape 7 : Tester

```bash
# Depuis ton PC ou n'importe où
curl http://<IP_VPS>:3000/request-channel
curl http://<IP_VPS>:3000/withdraw-request
curl http://<IP_VPS>:3000/auth
```

---

## 🔧 Configuration Post-Installation

### Service Systemd (Auto-restart)

Le serveur LNURL est configuré comme service systemd :

```bash
# Voir les logs en temps réel
sudo journalctl -u lnurl-server -f

# Redémarrer le serveur
sudo systemctl restart lnurl-server

# Voir le statut
sudo systemctl status lnurl-server
```

### Surveillance

```bash
# Bitcoin sync
watch -n 10 'bitcoin-cli -testnet4 getblockchaininfo | jq ".blocks, .initialblockdownload"'

# Lightning status
watch -n 5 'lightning-cli --network=testnet4 getinfo | jq ".id, .num_peers, .num_active_channels"'

# Serveur LNURL
curl http://localhost:3000/request-channel
```

---

## 🛡️ Sécurité

### Recommandations

1. **Créer un utilisateur non-root**
   ```bash
   adduser lnurl
   usermod -aG sudo lnurl
   # Copier les configs dans /home/lnurl/
   ```

2. **Désactiver login root SSH**
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Changer : PermitRootLogin no
   sudo systemctl restart sshd
   ```

3. **Firewall déjà configuré** (ufw)

4. **Sauvegardes régulières**
   ```bash
   # Sauvegarder le wallet
   bitcoin-cli -testnet4 -rpcwallet=lnurl_wallet backupwallet ~/wallet-backup.dat
   ```

---

## 💰 Coûts Mensuels Estimés

| Provider | Plan | Prix | RAM | Storage | Bande Passante |
|----------|------|------|-----|---------|----------------|
| Hetzner | CPX11 | 4.51€ | 2GB | 40GB | 20TB |
| Contabo | VPS S | 4.99€ | 6GB | 100GB | 32TB |
| DigitalOcean | Basic | 6$ | 1GB | 25GB | 1TB |
| Oracle | Free Tier | 0€ | 1GB | 50GB | 10TB |

**Recommandation finale :** Hetzner CPX11 (4.51€/mois)

---

## 📞 Communication avec le Prof

### Email Suggéré

```
Objet : Projet LNURL - VPS Déployé

Bonjour,

Suite à vos recommandations, j'ai déployé mon stack LNURL sur un VPS Linux 
(résout le problème de stabilité WSL).

Infrastructure :
- Bitcoin Core v30.2.0 (testnet4, synchronisé)
- Core Lightning v25.12.1 (compilé avec --disable-rust pour stabilité)
- Serveur LNURL (3 commandes client + 6 endpoints serveur)

Accès :
- IP : <TON_IP_VPS>
- Endpoints : http://<TON_IP_VPS>:3000/request-channel
- Node ID Lightning : <TON_NODE_ID>

Le serveur est disponible 24/7. N'hésitez pas à le tester quand vous voulez.

Cordialement,
Sacha
```

---

## ⏱️ Timeline Estimée

- **Création VPS :** 5 minutes
- **Script d'installation :** 10 minutes
- **Synchronisation Bitcoin :** 30-60 minutes
- **Tests finaux :** 10 minutes

**Total : ~1h-1h30** (principalement attente sync Bitcoin)

---

## 🆘 Alternative : Laptop + Port Forwarding

Si vraiment tu ne peux pas faire de VPS, voici la procédure pour ton laptop :

### 1. Redirection de Port sur ta Box

1. Aller dans l'interface de ta box (192.168.1.1 généralement)
2. Trouver "NAT/PAT" ou "Port Forwarding"
3. Ajouter une règle :
   - **Port externe :** 3000
   - **Port interne :** 3000
   - **IP locale :** <IP_DE_TON_PC> (trouver avec `ipconfig`)
   - **Protocole :** TCP

### 2. Trouver ton IP Publique

```bash
curl ifconfig.me
```

### 3. Script de Démarrage

```bash
cd "/mnt/c/Sacha/Cours/LN version 2"
./start-infrastructure.sh
```

### 4. Convenir d'une Date avec le Prof

```
Bonjour,

J'ai configuré mon laptop avec redirection de port.
Pouvons-nous convenir d'une date/heure où je m'assure 
que ma machine est en ligne ?

Proposition : [DATE] entre [HEURE] et [HEURE]

Mon IP publique : <TON_IP>
Port : 3000

Cordialement
```

---

## ✅ Conclusion

**Meilleure option :** VPS Linux (Hetzner 4.51€/mois)
- Résout le problème WSL définitivement
- Disponible 24/7
- Compétence utile pour ta carrière
- Le prof peut tester quand il veut

**Script fourni fait tout automatiquement** - tu n'as qu'à :
1. Créer le VPS
2. Lancer le script
3. Attendre la sync
4. Informer le prof

🚀 **Go pour le VPS ?**
