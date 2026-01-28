# 🚀 Guide de Démarrage Rapide

## Option 1 : Test rapide (SANS nœud Lightning local)

Si vous voulez juste tester la connexion HTTP au serveur :

### Sous Windows (PowerShell)
```powershell
cd "c:\Sacha\Cours\LN version 2\lnurl-client-test"
.\target\release\lnurl-client-test.exe request-channel 82.67.177.113:3001
```

### Sous WSL
```bash
curl http://82.67.177.113:3001/request-channel | jq
```

---

## Option 2 : Installation complète (AVEC nœud Lightning local)

### Étape 1 : Ouvrir WSL
```powershell
wsl -d Ubuntu
```

### Étape 2 : Lancer l'installation automatique
```bash
cd /mnt/c/Sacha/Cours/'LN version 2'
./install.sh
```

Ce script va installer :
- Bitcoin Core v27.0
- Core Lightning (dernière version stable)
- Toutes les dépendances nécessaires
- Configurer automatiquement tout

⏱️ **Durée estimée** : 10-20 minutes (selon votre connexion)

### Étape 3 : Démarrer les services
```bash
./start.sh
```

Cela va démarrer :
- Bitcoin Core en mode testnet4
- Core Lightning connecté à Bitcoin Core

### Étape 4 : Attendre la synchronisation

Bitcoin Core doit se synchroniser avec testnet4. Vérifiez la progression :

```bash
watch -n 5 'bitcoin-cli -testnet4 getblockchaininfo | grep -E "blocks|initialblockdownload"'
```

⏱️ **Durée** : Peut prendre 1-2 heures pour testnet4

### Étape 5 : Tester le client LNURL

Une fois synchronisé :

```bash
cd ~/LN_version_2/lnurl-client
cargo run --release -- request-channel 82.67.177.113:3001
```

---

## 🛠️ Commandes utiles

### Bitcoin Core
```bash
# Infos sur la blockchain
bitcoin-cli -testnet4 getblockchaininfo

# Nouvelle adresse de réception
bitcoin-cli -testnet4 getnewaddress

# Solde
bitcoin-cli -testnet4 getbalance

# Arrêter
bitcoin-cli -testnet4 stop
```

### Core Lightning
```bash
# Infos sur le nœud
lightning-cli --network=testnet4 getinfo

# Liste des fonds
lightning-cli --network=testnet4 listfunds

# Liste des canaux
lightning-cli --network=testnet4 listchannels

# Arrêter
lightning-cli --network=testnet4 stop
```

### Scripts de gestion
```bash
# Démarrer tout
./start.sh

# Arrêter tout
./stop.sh

# Vérifier les logs
tail -f ~/.bitcoin/testnet4/debug.log      # Bitcoin
tail -f /tmp/lightningd.log                 # Lightning
```

---

## 🐛 Dépannage

### Bitcoin Core ne démarre pas

1. Vérifier les logs :
   ```bash
   tail -100 ~/.bitcoin/testnet4/debug.log
   ```

2. Vérifier qu'aucun autre processus n'utilise le port :
   ```bash
   lsof -i :48332
   ```

3. Supprimer le fichier de lock si nécessaire :
   ```bash
   rm ~/.bitcoin/testnet4/.lock
   ```

### Core Lightning ne démarre pas

1. Vérifier que Bitcoin Core est démarré :
   ```bash
   bitcoin-cli -testnet4 getblockchaininfo
   ```

2. Vérifier les logs Lightning :
   ```bash
   tail -100 /tmp/lightningd.log
   ```

3. Vérifier la configuration :
   ```bash
   cat ~/.lightning/config
   ```

### Le client ne se connecte pas

1. Vérifier que le socket RPC existe :
   ```bash
   ls -l ~/.lightning/testnet4/lightning-rpc
   ```

2. Vérifier que le nœud répond :
   ```bash
   lightning-cli --network=testnet4 getinfo
   ```

3. Vérifier le chemin dans le code :
   ```bash
   grep "CLN_RPC_PATH" ~/LN_version_2/lnurl-client/src/main.rs
   ```

---

## 📝 Pour rendre le projet

Le prof teste avec :
```bash
git clone <votre_repo>
cd <votre_repo>
cargo run -- request-channel 82.67.177.113:3001
```

Assurez-vous que :
- ✅ Le client compile sans erreur
- ✅ Il se connecte au serveur `82.67.177.113:3001`
- ✅ Il affiche une réponse du serveur
- ✅ Votre code est sur GitHub

---

## ⏰ Timeline

- **Maintenant** : Test rapide avec `lnurl-client-test` (5 min)
- **Ce soir/demain** : Installation complète (30 min)
- **Synchronisation** : Laisser tourner pendant la nuit
- **Mardi prochain** : Tests finaux et soumission

---

## 💡 Conseils

1. **Commencez par tester le client simplifié** pour valider que le serveur fonctionne
2. **Laissez Bitcoin Core synchroniser en arrière-plan** (utilisez `tmux` ou `screen`)
3. **Faites des commits réguliers** sur Git
4. **Testez tôt**, ne attendez pas la dernière minute
5. **Documentez vos problèmes** pour pouvoir demander de l'aide

---

## 🆘 Besoin d'aide ?

Si vous rencontrez des problèmes :
1. Vérifiez les logs (ci-dessus)
2. Demandez sur le canal du cours
3. Consultez la documentation officielle
4. GitHub Issues des projets

Bon courage ! 🚀
