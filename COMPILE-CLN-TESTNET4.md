# Instructions pour compiler Core Lightning avec support testnet4

## Le problème
Core Lightning v24.11.2 ne supporte pas testnet4.  
La version master (HEAD) **supporte testnet4** ✓

## Solution : Compiler CLN master

### Étape 1 : Ouvrir WSL
```powershell
wsl -d Ubuntu
```

### Étape 2 : Aller dans le répertoire Lightning
```bash
cd ~/lightning
```

### Étape 3 : Vérifier qu'on est sur master avec testnet4
```bash
git log --oneline -1
# Devrait afficher: d5f66ceab (ou plus récent)

grep -n "testnet4" common/configdir.c
# Devrait afficher des lignes avec testnet4
```

### Étape 4 : Compiler (5-10 minutes)
```bash
# Méthode simple (sans plugins Rust)
make -j4

# OU si Poetry fonctionne:
export PATH="$HOME/.local/bin:$PATH"
poetry run make -j4
```

**Attendez que la compilation se termine**. Vous verrez défiler plein de lignes avec `CC`, `LINK`, etc.

### Étape 5 : Vérifier la compilation
```bash
# Vérifier que lightningd existe
ls -lh lightningd/lightningd

# Vérifier la version
./lightningd/lightningd --version
```

### Étape 6 : Installer
```bash
sudo make install
```

### Étape 7 : Vérifier l'installation
```bash
lightningd --version
# Devrait afficher v25.x-xxx-modded

# Vérifier le support testnet4
lightningd --help | grep testnet4
# Devrait afficher : --testnet4  Alias for --network=testnet4
```

## Après la compilation réussie

### Mise à jour de la configuration Lightning
Fichier : `~/.lightning/config`

```ini
# CHANGEMENT : testnet -> testnet4
network=testnet4
log-level=info
log-file=/tmp/lightningd.log

# Bitcoin Core RPC (reste identique)
bitcoin-rpcuser=lnurl_user
bitcoin-rpcpassword=ChangeMeToSecurePassword123
bitcoin-rpcport=48332

# Réseau
bind-addr=0.0.0.0:49735
announce-addr=127.0.0.1:49735

# Plugin désactivé
disable-plugin=/usr/local/libexec/c-lightning/plugins/clnrest/clnrest.py
```

### Démarrer Lightning avec testnet4
```bash
# Bitcoin Core doit déjà tourner en testnet4
lightningd --network=testnet4 --daemon

# Vérifier
sleep 3
lightning-cli --network=testnet4 getinfo
```

### Mettre à jour le client LNURL
Fichier : `~/LN_version_2/lnurl-client/src/main.rs`  
Ligne 10 :

```rust
// AVANT (ne fonctionne pas)
const CLN_RPC_PATH: &str = "/home/sosthene/.lightning/testnet4/lightning-rpc";

// APRÈS (votre utilisateur + testnet4)
const CLN_RPC_PATH: &str = "/home/sgotz/.lightning/testnet4/lightning-rpc";
```

Recompiler :
```bash
cd ~/LN_version_2/lnurl-client
cargo build --release
```

### Tester le client complet
```bash
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001
```

**Résultat attendu** : Le client devrait maintenant :
1. ✓ Se connecter au serveur HTTP
2. ✓ Récupérer l'URI du nœud distant
3. ✓ Se connecter à votre nœud Lightning local
4. ✓ Se connecter au nœud distant
5. ✓ Demander l'ouverture du canal

## En cas d'erreur

### Erreur de compilation
```bash
# Nettoyer et réessayer
cd ~/lightning
make clean
./configure --enable-developer
make -j4
```

### Erreur "poetry not found"
```bash
# Compiler sans Poetry (plugins Rust désactivés)
make -j4
```

### Erreur de dépendances manquantes
```bash
sudo apt install -y autoconf automake build-essential git libtool \
    libsqlite3-dev python3 python3-pip net-tools zlib1g-dev \
    libsodium-dev gettext libgmp-dev libssl-dev lowdown
```

## Vérification finale

Une fois tout installé et configuré :

```bash
# 1. Bitcoin Core tourne ?
bitcoin-cli -testnet4 getblockchaininfo | jq .chain
# → "testnet4"

# 2. Lightning tourne ?
lightning-cli --network=testnet4 getinfo | jq .network
# → "testnet4"

# 3. Client fonctionne ?
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001
# → Devrait ouvrir un canal !
```

## Timeline

- **Compilation** : 5-10 minutes
- **Configuration** : 2 minutes
- **Tests** : 5 minutes

**Total : ~15-20 minutes pour avoir testnet4 fonctionnel**

Bon courage ! 🚀
