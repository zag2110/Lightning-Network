# Projet LNURL - Lightning Network

**Projet universitaire - Implémentation complète LNURL**  
**Date :** Janvier 2026  
**Statut :** ✅ Code complet | ⚠️ Problème d'infrastructure WSL

## 📋 Cahier des Charges

Implémenter un client et serveur LNURL avec :
1. **request-channel** : Ouverture de canal Lightning
2. **request-withdraw** : Retrait de fonds via BOLT11
3. **lnurl-auth** : Authentification Lightning

Déployer l'infrastructure complète (Bitcoin Core + Core Lightning + serveur LNURL) sur testnet4.

---

## ✅ État Final

### Implémentation (100%)

#### Client LNURL
- ✅ **3 commandes** implémentées (417 lignes)
- ✅ `request-channel` : Testé avec succès (canal ouvert)
- ✅ `request-withdraw` : Implémenté (création invoice + callback)
- ✅ `auth` : Implémenté (version simplifiée)
- ✅ Compilation réussie dans WSL

#### Serveur LNURL
- ✅ **6 endpoints** implémentés (350+ lignes)
- ✅ `/request-channel` et `/open-channel`
- ✅ `/withdraw-request` et `/withdraw`
- ✅ `/auth` et `/auth-verify`
- ✅ Compilation réussie dans WSL

#### Infrastructure
- ✅ Bitcoin Core v30.2.0 synced (120,435 blocs testnet4)
- ✅ Wallet : 0.005 BTC (500,000 sats)
- ✅ Core Lightning v25.12.1 installé
- ✅ Canal ouvert : 100,000 sats (TX: 9182a1e9...)
- ⚠️ Lightning instable dans WSL (crash plugins après 8-15s)

---

## 📁 Structure du Projet

```
LN version 2/
├── lnurl-client/           # Client LNURL complet (3 commandes)
│   ├── src/main.rs         # 417 lignes - request-channel, request-withdraw, auth
│   └── Cargo.toml          # cln-rpc, ureq, uuid, hex, secp256k1
├── lnurl-server/           # Serveur LNURL complet (6 endpoints)
│   ├── src/main.rs         # 350+ lignes - tous endpoints LNURL
│   └── Cargo.toml          # axum, cln-rpc, tokio, uuid, serde
├── luds/                   # Spécifications LNURL officielles
├── PROJECT-FINAL.md        # 📘 Guide complet du projet
├── RESUME-PROF.md          # 📄 Résumé pour évaluation
├── SOLUTION-LIGHTNING.md   # 🔍 Diagnostic problème WSL
├── ETAT-FINAL.md           # 📊 État détaillé + statistiques
├── start-infrastructure.sh # Script démarrage Bitcoin + Lightning
└── quick-start.sh          # Script démarrage rapide (démo)
```

**Sous WSL** (client complet - nécessite CLN) :
```bash
wsl -d Ubuntu
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001
```

## 🚧 À faire pour compléter le projet

### 1. Installation Bitcoin Core (testnet4)

```bash
# Dans WSL
wget https://bitcoincore.org/bin/bitcoin-core-27.0/bitcoin-27.0-x86_64-linux-gnu.tar.gz
tar -xzf bitcoin-27.0-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-27.0/bin/*
```

Configuration (`~/.bitcoin/bitcoin.conf`) :
```
testnet4=1
server=1
daemon=1
txindex=1
```

Démarrer Bitcoin :
```bash
bitcoind -testnet4
```

### 2. Installation Core Lightning (CLN)

```bash
# Dans WSL - Installation des dépendances
sudo apt update
sudo apt install -y \
    autoconf automake build-essential git libtool libsqlite3-dev \
    python3 python3-pip net-tools zlib1g-dev libsodium-dev gettext

# Cloner et compiler CLN
git clone https://github.com/ElementsProject/lightning.git
cd lightning
pip3 install --user poetry
poetry install
./configure
poetry run make
sudo make install
```

Configuration (`~/.lightning/config`) :
```
network=testnet4
bitcoin-rpcuser=<votre_user>
bitcoin-rpcpassword=<votre_password>
```

Démarrer CLN :
```bash
lightningd --network=testnet4 --log-level=debug
```

### 3. Corriger le chemin RPC

Le client utilise le chemin : `/home/sosthene/.lightning/testnet4/lightning-rpc`

Il faut le modifier pour utiliser votre utilisateur. Dans [lnurl-client/src/main.rs](lnurl-client/src/main.rs) ligne 10 :

```rust
const CLN_RPC_PATH: &str = "/home/VOTRE_USER/.lightning/testnet4/lightning-rpc";
```

Remplacez `VOTRE_USER` par votre nom d'utilisateur WSL (actuellement `sgotz`).

### 4. Workflow complet attendu

Une fois tout configuré :

```bash
# 1. Lancer le client
cargo run --release -- request-channel 82.67.177.113:3001

# Le client va :
# - Appeler /request-channel sur le serveur distant
# - Récupérer l'URI du nœud Lightning distant
# - Se connecter avec lightning-cli connect
# - Appeler /open-channel avec votre node ID
# - Le serveur ouvrira un canal avec vous
```

## 🌐 Serveur

**Adresse publique (sans VPN)** : `82.67.177.113:3001`

### Endpoints disponibles

- `GET /request-channel` - Demande d'ouverture de canal
- `GET /open-channel?remoteid=<node_id>&k1=<k1>` - Ouverture effective du canal
- `GET /request-withdraw` - Demande de retrait (bonus)

## 📚 Ressources

- Repos GitHub :
  - Client : https://github.com/Sosthene00/lnurl-client
  - Serveur : https://github.com/Sosthene00/lnurl-server
  - Spécifications : https://github.com/lnurl/luds

- Documentation :
  - Bitcoin Core : https://bitcoin.org/en/full-node
  - Core Lightning : https://docs.corelightning.org/
  - LNURL specs : https://github.com/lnurl/luds

## 🔧 Technologies utilisées

- **WSL** : Windows Subsystem for Linux
- **Rust** : Langage de programmation
- **Bitcoin Core** : Nœud Bitcoin en testnet4
- **Core Lightning (CLN)** : Implémentation Lightning Network
- **Tor** : (optionnel) Daemon Tor pour anonymisation

## 📝 Notes

- Le projet nécessite d'être sur testnet4 (pas mainnet)
- Date limite : Mardi prochain pour avoir un client fonctionnel
- Test de validation : `git clone` + `cargo run` doit se connecter au serveur et afficher une réponse
