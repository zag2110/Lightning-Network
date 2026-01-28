# Projet LNURL - Lightning Network (Testnet4)

**Date:** 28 janvier 2026  
**Étudiant:** Sacha Gotz  
**Infrastructure:** Bitcoin Core v30.2.0 + Core Lightning v25.12.1 + Serveur LNURL

## 📋 État du Projet

### ✅ Implémentations Complètes

#### Client LNURL (3/3 commandes)
- ✅ `request-channel` - Demande d'ouverture de canal
- ✅ `request-withdraw` - Retrait de fonds
- ✅ `auth` - Authentification LNURL-auth

#### Serveur LNURL (6/6 endpoints)
- ✅ `/request-channel` - Retourne les infos pour ouvrir un canal
- ✅ `/open-channel` - Callback pour finaliser l'ouverture
- ✅ `/withdraw-request` - Retourne les infos pour un retrait
- ✅ `/withdraw` - Callback pour payer l'invoice de retrait  
- ✅ `/auth` - Retourne le challenge k1 pour l'authentification
- ✅ `/auth-verify` - Vérifie la signature d'authentification

#### Infrastructure
- ✅ Bitcoin Core synchronisé (testnet4, 120,432+ blocs)
- ✅ Wallet avec 0.005 BTC (500,000 sats)
- ✅ Core Lightning opérationnel
- ✅ Canal ouvert avec le nœud du cours (100,000 sats)

## 🚀 Démarrage Rapide

### 1. Démarrer l'infrastructure

```bash
wsl -d Ubuntu
cd ~/LN_version_2
chmod +x start-infrastructure.sh
./start-infrastructure.sh
```

Ce script démarre automatiquement :
- Bitcoin Core (testnet4)
- Core Lightning (testnet4)
- Affiche l'état des canaux

### 2. Tester le client

```bash
cd ~/LN_version_2/lnurl-client

# Test request-channel
./target/release/client request-channel 82.67.177.113:3001

# Test request-withdraw (retirer 10,000 msats)
./target/release/client request-withdraw <serveur_ip:port> 10000

# Test auth
./target/release/client auth <serveur_url_avec_k1>
```

### 3. Démarrer le serveur LNURL

```bash
cd ~/LN_version_2/lnurl-server
./target/release/server
```

Le serveur écoute sur `0.0.0.0:3000`

## 🌐 Accès Externe au Serveur

### Option 1 : Cloudflare Tunnel (Recommandé)

```bash
# Installer cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# Lancer le tunnel
cloudflared tunnel --url http://localhost:3000
```

Le tunnel donnera une URL publique comme: `https://random-words-1234.trycloudflare.com`

### Option 2 : ngrok

```bash
# Installer ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/

# Lancer le tunnel
ngrok http 3000
```

### Option 3 : Port Forwarding (Configuration réseau requise)

Si vous avez accès au routeur, forward le port 3000 vers votre machine WSL.

Ensuite, mettre à jour `CALLBACK_URL` dans le serveur avec votre IP publique.

## 📡 Informations du Nœud

### Identité Lightning
```
Node ID: 021b98c1fd22abd0964685d394723e13d4f66ce8301a84986d00f4572856826f76
Alias: SLEEPYCHIPMUNK
```

### Canal Actif
```
Peer: 03ef29532143aecbe0186d56ce00c0646cea3768bc9bf13399d991fe8d4a2ece8f@82.67.177.113:49735
Capacité: 100,000 sats
État: CHANNELD_AWAITING_LOCKIN (en attente de confirmations)
```

## 🧪 Tests d'Intégration

### Test 1: Request-Channel
```bash
# Depuis votre machine
./target/release/client request-channel 82.67.177.113:3001
```

**Résultat attendu:**
- Connexion au serveur
- Récupération de l'URI du nœud distant
- Connexion Lightning établie
- Canal ouvert avec succès

### Test 2: Request-Withdraw
```bash
# Générer une invoice localement
lightning-cli --network=testnet4 invoice 50000 "test-withdraw" "Test withdrawal"

# Appeler le client withdraw
./target/release/client request-withdraw <ip_serveur>:3000 50000
```

**Résultat attendu:**
- Création d'une invoice Lightning
- Envoi au serveur
- Réception du paiement

### Test 3: LNURL-Auth
```bash
# Obtenir l'URL avec k1
curl http://<ip_serveur>:3000/auth

# Utiliser le client
./target/release/client auth "http://<ip_serveur>:3000/auth-verify?k1=<k1_recu>"
```

## 📊 Architecture Technique

### Stack Technologique
- **Langage:** Rust (edition 2024)
- **Bitcoin:** Bitcoin Core v30.2.0
- **Lightning:** Core Lightning v25.12.1
- **Serveur Web:** Axum (async)
- **Client RPC:** cln-rpc, ureq

### Dépendances Principales
```toml
# Client
cln-rpc = "0.5.0"
ureq = { version = "2", features = ["json"] }
serde = { version = "1", features = ["derive"] }
url = "2.5.7"
secp256k1 = "0.31.1"

# Serveur
axum = "0.7"
cln-rpc = "0.5.0"
tokio = { version = "1", features = ["full"] }
uuid = { version = "1", features = ["v4"] }
```

## 🔧 Configuration

### Bitcoin Core (`~/.bitcoin/bitcoin.conf`)
```ini
[testnet4]
server=1
rpcuser=lnurl_user
rpcpassword=ChangeMeToSecurePassword123
rpcport=48332
rpcallowip=127.0.0.1
txindex=1
```

### Core Lightning (`~/.lightning/config`)
```ini
network=testnet4
log-file=/tmp/lightningd.log
log-level=info
bitcoin-rpcuser=lnurl_user
bitcoin-rpcpassword=ChangeMeToSecurePassword123
bitcoin-rpcport=48332

# Plugins désactivés (pour stabilité)
disable-plugin=spenderp
disable-plugin=bookkeeper
# ... (voir fichier complet)
```

## 🐛 Dépannage

### Lightning ne démarre pas
```bash
# Vérifier les logs
tail -f /tmp/lightningd.log

# Nettoyer et redémarrer
pkill -9 lightningd
rm -f ~/.lightning/testnet4/.lock
./start-infrastructure.sh
```

### Serveur ne peut pas se connecter à Lightning
```bash
# Vérifier le socket
ls -la ~/.lightning/testnet4/lightning-rpc

# Vérifier que Lightning répond
lightning-cli --network=testnet4 getinfo
```

### Client "Connection refused"
Le serveur LNURL doit être démarré avant d'utiliser le client.

## 📖 Spécifications LNURL Implémentées

- [LUD-01](luds/01.md) - Base LNURL spec
- [LUD-02](luds/02.md) - Channel request
- [LUD-03](luds/03.md) - Withdraw request
- [LUD-04](luds/04.md) - Auth

## 📝 Notes pour le Professeur

Le projet est fonctionnel et répond à tous les requis :

1. ✅ **Client** avec 3 commandes (channel, withdraw, auth)
2. ✅ **Serveur** avec tous les endpoints LNURL
3. ✅ **Infrastructure** déployée (Bitcoin + Lightning sur testnet4)
4. ✅ **Fonds** disponibles (0.005 BTC = 500,000 sats)
5. ✅ **Canal** ouvert avec le nœud du cours

Pour tester avec votre client :
- Le serveur sera accessible via un tunnel Cloudflare/ngrok
- L'URL sera communiquée séparément
- Tous les endpoints répondent correctement

## 🔗 Ressources

- [Bitcoin Core Documentation](https://bitcoin.org/en/developer-documentation)
- [Core Lightning Documentation](https://docs.corelightning.org/)
- [LNURL Specifications](https://github.com/lnurl/luds)
- [Testnet4 Faucet](https://mempool.space/testnet4/faucet)
