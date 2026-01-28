# ✅ Solution finale : Core Lightning avec testnet4

## 🎯 Problème résolu

**CLN master supporte testnet4 !** ✓

J'ai vérifié le code source :
- `common/configdir.c` ligne 348-350 : support de `--testnet4`
- Vous êtes déjà sur master (commit d5f66ceab)
- Il suffit de compiler !

## 🚀 Procédure complète (15-20 minutes)

### Étape 1 : Ouvrir un nouveau terminal WSL

```powershell
wsl -d Ubuntu
```

### Étape 2 : Compiler Core Lightning

```bash
cd ~/lightning
make -j4
```

**⏱️ Cela prend 5-10 minutes**. Vous verrez défiler plein de lignes avec `CC`, `LINK`, etc.

### Étape 3 : Installer

```bash
sudo make install
```

### Étape 4 : Vérifier l'installation

```bash
lightningd --version
# Devrait afficher : v25.x-xxx-modded

lightningd --help | grep testnet4
# Devrait afficher : --testnet4  Alias for --network=testnet4
```

### Étape 5 : Lancer le script de configuration automatique

```bash
bash "/mnt/c/Sacha/Cours/LN version 2/post-install-cln.sh"
```

Ce script va :
- ✅ Mettre à jour `~/.lightning/config` avec `network=testnet4`
- ✅ Mettre à jour le chemin RPC dans le client
- ✅ Recompiler le client

### Étape 6 : Démarrer Lightning

```bash
# Vérifier que Bitcoin Core tourne
bitcoin-cli -testnet4 getblockchaininfo

# Démarrer Lightning
lightningd --network=testnet4 --daemon

# Attendre le démarrage
sleep 5

# Vérifier
lightning-cli --network=testnet4 getinfo
```

### Étape 7 : Tester le client complet

```bash
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001
```

**Résultat attendu** :
```
Requesting channel info from http://82.67.177.113:3001/...
Node URI: ...
Received channel request:
  URI: 03ef...@82.67.177.113:49735
  Callback: http://82.67.177.113:3001/open-channel
  k1: ...

Connecting to node ...
Requesting channel open...
Channel opened successfully!
```

## 📁 Fichiers créés

Trois fichiers ont été créés pour vous aider :

1. **COMPILE-CLN-TESTNET4.md** - Guide détaillé étape par étape
2. **compile-cln.sh** - Script de compilation (optionnel, peut avoir des problèmes)
3. **post-install-cln.sh** - Script de configuration post-installation ✓

## 🐛 Dépannage

### La compilation échoue

**Dépendances manquantes** :
```bash
sudo apt install -y autoconf automake build-essential git libtool \
    libsqlite3-dev python3 python3-pip net-tools zlib1g-dev \
    libsodium-dev gettext libgmp-dev libssl-dev lowdown
```

**Nettoyer et réessayer** :
```bash
cd ~/lightning
make clean
./configure --enable-developer
make -j4
```

### Lightning ne démarre pas

**Voir les logs** :
```bash
tail -f /tmp/lightningd.log
```

**Démarrer en premier plan pour debug** :
```bash
lightningd --network=testnet4 --log-level=debug
```

### Le client ne trouve pas le socket RPC

**Vérifier le chemin** :
```bash
ls -la ~/.lightning/testnet4/lightning-rpc
```

**Vérifier le code** :
```bash
grep "CLN_RPC_PATH" ~/LN_version_2/lnurl-client/src/main.rs
# Doit afficher : /home/sgotz/.lightning/testnet4/lightning-rpc
```

## ⚡ Workflow complet final

Une fois tout configuré, voici le workflow :

```bash
# 1. Bitcoin Core (devrait déjà tourner)
bitcoin-cli -testnet4 getblockchaininfo

# 2. Lightning
lightningd --network=testnet4 --daemon
lightning-cli --network=testnet4 getinfo

# 3. Obtenir des fonds testnet4 (si besoin)
bitcoin-cli -testnet4 getnewaddress
# → Utiliser un faucet testnet4

# 4. Tester le client LNURL
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001

# 5. Voir les canaux
lightning-cli --network=testnet4 listfunds
lightning-cli --network=testnet4 listpeerchannels
```

## 🎓 Pour rendre le projet

Maintenant vous avez **deux versions** :

### Version minimale (déjà prête pour mardi)
```bash
cd ~/LN_version_2/lnurl-client-test
cargo run --release -- request-channel 82.67.177.113:3001
```
✅ Se connecte au serveur  
✅ Affiche la réponse  
✅ Répond aux critères minimaux

### Version complète (avec testnet4 + Lightning)
```bash
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001
```
✅ Tout ce qui précède +  
✅ Se connecte au nœud Lightning local  
✅ Se connecte au nœud distant  
✅ Ouvre un canal Lightning

## 📝 Résumé des commandes essentielles

```bash
# === COMPILATION (une seule fois) ===
cd ~/lightning
make -j4
sudo make install

# === CONFIGURATION (une seule fois) ===
bash "/mnt/c/Sacha/Cours/LN version 2/post-install-cln.sh"

# === UTILISATION QUOTIDIENNE ===
# Démarrer
lightningd --network=testnet4 --daemon

# Vérifier
lightning-cli --network=testnet4 getinfo

# Arrêter
lightning-cli --network=testnet4 stop

# Tester le client
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001
```

---

## ✅ Checklist finale

Avant de soumettre votre projet :

- [ ] CLN compilé et installé
- [ ] `lightningd --help | grep testnet4` fonctionne
- [ ] Configuration mise à jour (`network=testnet4`)
- [ ] Bitcoin Core tourne en testnet4
- [ ] Lightning démarre avec `--network=testnet4`
- [ ] `lightning-cli --network=testnet4 getinfo` fonctionne
- [ ] Client compile : `cd ~/LN_version_2/lnurl-client && cargo build --release`
- [ ] Client se connecte au serveur : affiche l'URI et les infos
- [ ] (Bonus) Canal ouvert avec le serveur distant

**Temps total estimé : 20-30 minutes**

Bon courage ! 🚀
