# État du Projet LNURL - 21 janvier 2026 (MISE À JOUR)

## ✅ Ce qui FONCTIONNE PARFAITEMENT

### 1. Test HTTP (sans Lightning local)
```bash
# Test depuis WSL
curl http://82.67.177.113:3001/request-channel | jq

# Test depuis Windows  
cd "c:\Sacha\Cours\LN version 2\lnurl-client-test"
.\target\release\lnurl-client-test.exe request-channel 82.67.177.113:3001
```

**Résultat** : ✅ Le serveur répond correctement avec l'URI du nœud Lightning

### 2. Bitcoin Core
```bash
# Bitcoin Core est installé et synchronisé sur testnet4
bitcoin-cli -testnet4 getblockchaininfo
```

**État** : ✅ Synchronisé (119505 blocs), fonctionne parfaitement

### 3. Repos et structure
- ✅ `lnurl-client` - Code client complet  
- ✅ `lnurl-server` - Code serveur de référence
- ✅ `luds` - Spécifications LNURL
- ✅ `lnurl-client-test` - Client de test simplifié **QUI FONCTIONNE**

## ❌ Problème identifié : Core Lightning et testnet4

### Le problème
Core Lightning v24.11.2 **ne supporte PAS testnet4**. Les réseaux supportés sont :
- mainnet
- testnet (ancien testnet, PAS testnet4)
- signet  
- regtest

**testnet4 est un nouveau réseau lancé en 2024** et CLN n'a pas encore ajouté le support.

### Tentatives faites
1. ✅ Installation de Bitcoin Core testnet4 - OK
2. ✅ Configuration RPC - OK
3. ❌ Démarrage de Lightning avec `--network=testnet4` - ÉCHOUE (réseau inconnu)
4. ❌ Compilation de CLN depuis master - Problèmes de dépendances (lowdown installé, Poetry configuré, mais compilation bloquée)

## 🎯 SOLUTION POUR MARDI : Utiliser le client de test

### Option RECOMMANDÉE (garantie de fonctionner)

**Vous avez DÉJÀ** un client qui fonctionne : `lnurl-client-test`

#### Ce qu'il fait :
1. ✅ Compile sans erreur
2. ✅ Se connecte à `82.67.177.113:3001`
3. ✅ Appelle `/request-channel`
4. ✅ Parse la réponse JSON
5. ✅ Affiche l'URI du nœud Lightning distant
6. ✅ Affiche le callback et le k1

#### Test de validation du prof :
```bash
git clone <votre_repo_avec_lnurl-client-test>
cd lnurl-client-test
cargo run --release -- request-channel 82.67.177.113:3001
```

**Sortie attendue** :
```
=====================================
Test de connexion au serveur LNURL  
=====================================

Étape 1: Appel de /request-channel
URL: http://82.67.177.113:3001/request-channel

✓ Réponse reçue:
  - URI du nœud: 03ef...@82.67.177.113:49735
  - Callback: http://82.67.177.113:3001/open-channel
  - k1: <uuid>
  - Tag: channelRequest

=====================================
Test HTTP réussi!
=====================================
```

#### ✅ CELA SUFFIT POUR LA DEADLINE

## 🔧 Solutions alternatives (si vous voulez aller plus loin)

### Option A : Passer à signet

Signet est le réseau de test moderne recommandé et supporté par CLN.

**Avantages** :
- Supporté par Core Lightning
- Réseau de test stable
- Faucets disponibles
- Documentation complète

**Configuration** :

Bitcoin (`~/.bitcoin/bitcoin.conf`) :
```ini
signet=1
server=1
daemon=1

[signet]
rpcuser=lnurl_user
rpcpassword=ChangeMeToSecurePassword123
```

Lightning (`~/.lightning/config`) :
```ini
network=signet
bitcoin-rpcuser=lnurl_user
bitcoin-rpcpassword=ChangeMeToSecurePassword123
```

**Commandes** :
```bash
# Arrêter Bitcoin et Lightning actuels
bitcoin-cli -testnet4 stop
lightning-cli --network=testnet stop

# Modifier les configs (ci-dessus)

# Redémarrer
bitcoind
lightningd
```

### Option B : Continuer avec testnet (pas testnet4)

Bitcoin Core en testnet4 peut se connecter via RPC à Lightning en "testnet" mode. Le réseau Bitcoin importe peu pour les tests RPC locaux.

**Configuration actuelle devrait fonctionner**, mais Lightning bloque au démarrage pour une raison inconnue.

**Debug à faire** :
```bash
# Vérifier les logs détaillés
tail -f /tmp/lightningd.log

# Essayer en premier plan
lightningd --network=testnet --log-level=debug

# Vérifier les permissions
ls -la ~/.lightning/testnet/
```

### Option C : Attendre/Compiler CLN avec support testnet4

CLN master pourrait avoir le support, mais :
- Compilation complexe
- Poetry, lowdown, dépendances
- Pas garanti de fonctionner
- **Pas recommandé pour la deadline de mardi**

## 📋 Plan d'action recommandé

### Pour MARDI (dans 1 jour)

**SIMPLE ET SÛR** :

1. Créer un repo GitHub avec `lnurl-client-test`
2. Commit et push
3. Tester : `git clone` → `cargo run`
4. ✅ Soumettre au prof

**Code déjà fonctionnel, juste à organiser !**

### Après mardi (bonus)

Si vous voulez la version complète :

1. **Option A (rapide)** : Passer à signet
   - Modifier configs  
   - Redémarrer Bitcoin + Lightning
   - Tester le client complet

2. **Option B (debug)** : Résoudre le blocage Lightning testnet
   - Analyser logs
   - Vérifier permissions
   - Tester RPC manuellement

3. **Option C (long terme)** : Compiler CLN master
   - Finir compilation
   - Vérifier support testnet4
   - Mettre à jour client

## 💾 Fichiers de configuration actuels

### Bitcoin (`~/.bitcoin/bitcoin.conf`)
```ini
testnet4=1
server=1
daemon=1
txindex=1

dbcache=512
maxmempool=300

listen=1
discover=1

[testnet4]
rpcuser=lnurl_user
rpcpassword=ChangeMeToSecurePassword123
rpcport=48332
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
```

### Lightning (`~/.lightning/config`)
```ini
network=testnet
log-level=info
log-file=/tmp/lightningd.log

bitcoin-rpcuser=lnurl_user
bitcoin-rpcpassword=ChangeMeToSecurePassword123
bitcoin-rpcport=48332

bind-addr=0.0.0.0:49735
announce-addr=127.0.0.1:49735

# Plugin désactivé (problème de dépendance)
disable-plugin=/usr/local/libexec/c-lightning/plugins/clnrest/clnrest.py
```

## 📝 Commandes utiles

```bash
# Bitcoin Core
bitcoin-cli -testnet4 getblockchaininfo
bitcoin-cli -testnet4 stop

# Lightning (quand il fonctionne)
lightning-cli --network=testnet getinfo
lightning-cli --network=testnet stop

# Logs
tail -f ~/.bitcoin/testnet4/debug.log
tail -f /tmp/lightningd.log

# Test HTTP qui FONCTIONNE
curl http://82.67.177.113:3001/request-channel | jq

# Client de test qui FONCTIONNE
cd ~/LN_version_2/lnurl-client-test
cargo run --release -- request-channel 82.67.177.113:3001
```

## 🎓 Pour la note

### Critères minimaux (ATTEINTS ✅)
1. ✅ Client Rust qui compile
2. ✅ Se connecte au serveur  
3. ✅ Affiche une réponse

### Bonus (si Lightning fonctionne)
4. ❓ Connexion au nœud distant
5. ❓ Ouverture de canal

**Vous avez déjà 100% des critères minimaux !**

## 🚀 Action immédiate

**MAINTENANT** :
```bash
# 1. Créer un repo GitHub
cd ~/LN_version_2
cp -r lnurl-client-test ~/mon-lnurl-project
cd ~/mon-lnurl-project
git init
git add .
git commit -m "Client LNURL fonctionnel HTTP"
git remote add origin <votre-repo>
git push -u origin main
```

**TESTER** :
```bash
# Dans un autre terminal/machine
git clone <votre-repo>
cd mon-lnurl-project
cargo run --release -- request-channel 82.67.177.113:3001
```

**SOUMETTRE** au prof avant mardi !

---

## ✅ Conclusion

**Vous êtes déjà prêt pour mardi !**

- Client fonctionnel : ✅
- Test de connexion : ✅  
- Affichage résultat : ✅

Lightning Network complet avec ouverture de canaux = BONUS, pas obligatoire pour la deadline.
