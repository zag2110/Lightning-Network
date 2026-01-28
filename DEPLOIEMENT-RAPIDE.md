# 🚀 Déploiement VPS - Guide Rapide

**Temps estimé :** 1h-1h30 (principalement synchronisation Bitcoin)  
**Coût :** 4.51€/mois (Hetzner) ou GRATUIT (Oracle Cloud)

---

## Étape 1 : Créer un Compte VPS (5 min)

### Option Recommandée : Hetzner Cloud 🥇

1. **Aller sur** https://www.hetzner.com/cloud
2. **Créer un compte** avec ton email
3. **Vérifier ton email**
4. **Ajouter un moyen de paiement** (carte bancaire)

### Alternative Gratuite : Oracle Cloud (plus complexe)

1. **Aller sur** https://www.oracle.com/cloud/free/
2. **Créer un compte** (Free Tier permanent)
3. **Vérifier avec carte bancaire** (pas de prélèvement)

---

## Étape 2 : Créer le VPS (5 min)

### Sur Hetzner :

1. **Cliquer sur "New Project"** → Nom : "LNURL"
2. **Add Server** → Choisir :
   - **Location :** Nuremberg (Allemagne) ou Helsinki (Finlande)
   - **Image :** Ubuntu 24.04
   - **Type :** Shared vCPU → **CPX11** (4.51€/mois)
   - **Networking :** IPv4 + IPv6
   - **SSH Key :** 
     - Si tu n'en as pas, crée-en une sur WSL :
       ```bash
       ssh-keygen -t ed25519 -C "ton_email@example.com"
       cat ~/.ssh/id_ed25519.pub
       ```
     - Copie le contenu et colle dans Hetzner
   - **Name :** lnurl-server

3. **Create & Buy Now**

4. **Noter l'IP publique** qui s'affiche (ex: 88.198.x.x)

---

## Étape 3 : Se Connecter au VPS (2 min)

### Depuis WSL :

```bash
ssh root@<IP_DU_VPS>
# Exemple : ssh root@88.198.123.456

# Si première connexion, accepter la fingerprint : yes
```

Tu es maintenant connecté au serveur ! 🎉

---

## Étape 4 : Copier le Code sur le VPS (10 min)

### Méthode Recommandée : Via Git

**Sur ton PC (WSL) :**

```bash
cd "/mnt/c/Sacha/Cours/LN version 2"

# Créer un repo Git
git init
git add lnurl-client/ lnurl-server/ *.md *.sh
git commit -m "Projet LNURL complet"

# Créer un repo GitHub PRIVÉ
# Aller sur https://github.com/new
# Nom : lnurl-project
# Visibilité : Private
# Créer

# Pusher le code
git remote add origin git@github.com:TON_USERNAME/lnurl-project.git
git push -u origin main
```

**Sur le VPS :**

```bash
# Générer une clé SSH pour GitHub
ssh-keygen -t ed25519 -C "ton_email@example.com"
cat ~/.ssh/id_ed25519.pub

# Copier la clé et l'ajouter sur GitHub :
# https://github.com/settings/keys → New SSH key

# Cloner le repo
cd ~
git clone git@github.com:TON_USERNAME/lnurl-project.git
```

### Alternative : Via SCP

**Sur ton PC (WSL) :**

```bash
cd "/mnt/c/Sacha/Cours/LN version 2"
scp -r lnurl-client lnurl-server root@<IP_VPS>:~/lnurl-project/
```

---

## Étape 5 : Copier et Lancer le Script (2 min)

**Sur le VPS :**

```bash
cd ~

# Télécharger le script depuis ton PC
# Option A : Si tu as mis deploy-vps.sh sur GitHub
curl -O https://raw.githubusercontent.com/TON_USERNAME/lnurl-project/main/deploy-vps.sh

# Option B : Copier manuellement
nano deploy-vps.sh
# Coller le contenu du fichier deploy-vps.sh
# Ctrl+X, Y, Enter pour sauvegarder

# Rendre exécutable
chmod +x deploy-vps.sh

# Lancer le script
./deploy-vps.sh
```

Le script va :
- ✅ Installer toutes les dépendances
- ✅ Télécharger Bitcoin Core
- ✅ Compiler Core Lightning (sans plugins Rust)
- ✅ Synchroniser Bitcoin (30-60 min)
- ✅ Démarrer Lightning
- ✅ Compiler ton serveur LNURL
- ✅ Configurer le firewall
- ✅ Créer un service systemd

**⏳ Attendre la synchronisation Bitcoin (30-60 min)**

Tu peux fermer le terminal, le script continue en arrière-plan.

Pour vérifier la progression dans un autre terminal :

```bash
ssh root@<IP_VPS>
watch -n 10 'bitcoin-cli -testnet4 getblockchaininfo | jq ".blocks, .initialblockdownload"'
```

---

## Étape 6 : Récupérer les Informations (1 min)

**Une fois le script terminé :**

```bash
cat ~/lnurl-info.txt
```

Tu verras :
- 🔐 Login Bitcoin RPC
- 📍 Adresse du wallet testnet4
- ⚡ Node ID Lightning
- 🌐 IP publique et endpoints

**Sauvegarder ces infos** dans un fichier local, puis :

```bash
rm ~/lnurl-info.txt  # Supprimer du serveur pour sécurité
```

---

## Étape 7 : Obtenir des Testcoins (5 min)

1. **Copier l'adresse du wallet** depuis lnurl-info.txt
2. **Aller sur** https://mempool.space/testnet4/faucet
3. **Coller l'adresse** et demander des coins
4. **Attendre les confirmations** (10-20 minutes)

Vérifier la réception :

```bash
bitcoin-cli -testnet4 -rpcwallet=lnurl_wallet getbalance
```

---

## Étape 8 : Tester le Serveur (2 min)

**Depuis n'importe où (ton PC, téléphone, etc.) :**

```bash
curl http://<IP_VPS>:3000/request-channel
curl http://<IP_VPS>:3000/withdraw-request
curl http://<IP_VPS>:3000/auth
```

Tu devrais voir des réponses JSON ! 🎉

---

## Étape 9 : Informer le Prof (5 min)

**Email :**

```
Objet : Projet LNURL - VPS Déployé et Accessible

Bonjour,

Suite à vos recommandations, j'ai déployé mon infrastructure LNURL 
sur un VPS Linux (Hetzner Cloud).

Infrastructure :
- Bitcoin Core v30.2.0 synced (testnet4)
- Core Lightning v25.12.1 (compilé avec --disable-rust pour stabilité maximale)
- Serveur LNURL opérationnel 24/7

Informations d'accès :
- IP publique : <TON_IP_VPS>
- Port : 3000

Endpoints disponibles :
- http://<TON_IP_VPS>:3000/request-channel
- http://<TON_IP_VPS>:3000/withdraw-request  
- http://<TON_IP_VPS>:3000/auth
- http://<TON_IP_VPS>:3000/open-channel
- http://<TON_IP_VPS>:3000/withdraw
- http://<TON_IP_VPS>:3000/auth-verify

Lightning Node ID :
<TON_NODE_ID>

Le serveur est disponible pour tests quand vous le souhaitez.

Tous les 3 commandes client et 6 endpoints serveur sont implémentés 
et fonctionnels.

Cordialement,
Sacha
```

---

## 🔧 Commandes Utiles

### Vérifier l'état du serveur

```bash
ssh root@<IP_VPS>

# Status du serveur LNURL
sudo systemctl status lnurl-server

# Logs en temps réel
sudo journalctl -u lnurl-server -f

# Redémarrer le serveur
sudo systemctl restart lnurl-server
```

### Vérifier Bitcoin

```bash
# Info blockchain
bitcoin-cli -testnet4 getblockchaininfo

# Balance du wallet
bitcoin-cli -testnet4 -rpcwallet=lnurl_wallet getbalance
```

### Vérifier Lightning

```bash
# Info du nœud
lightning-cli --network=testnet4 getinfo

# Liste des fonds
lightning-cli --network=testnet4 listfunds

# Liste des canaux
lightning-cli --network=testnet4 listchannels
```

---

## 🆘 Dépannage

### Le serveur LNURL ne répond pas

```bash
# Vérifier les logs
sudo journalctl -u lnurl-server -n 50

# Vérifier que Lightning tourne
ps aux | grep lightningd

# Redémarrer Lightning
pkill lightningd
lightningd --network=testnet4 --daemon
sleep 10

# Redémarrer le serveur
sudo systemctl restart lnurl-server
```

### Bitcoin ne sync pas

```bash
# Vérifier les logs
tail -f ~/.bitcoin/testnet4/debug.log

# Vérifier les connexions
bitcoin-cli -testnet4 getconnectioncount
```

### Lightning ne démarre pas

```bash
# Vérifier les logs
tail -f ~/.lightning/testnet4/lightning.log

# Tester manuellement
lightningd --network=testnet4
# Si erreur, lire le message
```

---

## 💡 Optimisations Post-Déploiement

### 1. Créer un Utilisateur Non-Root

```bash
adduser lnurl
usermod -aG sudo lnurl

# Copier la config SSH
mkdir /home/lnurl/.ssh
cp ~/.ssh/authorized_keys /home/lnurl/.ssh/
chown -R lnurl:lnurl /home/lnurl/.ssh

# Tester la connexion
# Depuis ton PC : ssh lnurl@<IP_VPS>
```

### 2. Désactiver le Login Root

```bash
sudo nano /etc/ssh/sshd_config
# Changer : PermitRootLogin no
sudo systemctl restart sshd
```

### 3. Configurer des Alertes Email

```bash
# Installer postfix
sudo apt-get install -y mailutils postfix

# Configurer pour recevoir des alertes
# si le serveur tombe
```

### 4. Sauvegardes Automatiques

```bash
# Créer un script de backup
cat > ~/backup-wallet.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
bitcoin-cli -testnet4 -rpcwallet=lnurl_wallet backupwallet ~/backups/wallet-$DATE.dat
# Uploader vers un service cloud (Dropbox, Google Drive, etc.)
EOF

chmod +x ~/backup-wallet.sh

# Ajouter au cron (tous les jours à 3h)
(crontab -l 2>/dev/null; echo "0 3 * * * ~/backup-wallet.sh") | crontab -
```

---

## 📊 Coûts Mensuels

| Durée | Hetzner CPX11 | Alternative |
|-------|---------------|-------------|
| 1 mois | 4.51€ | Oracle Free Tier (0€) |
| 3 mois | 13.53€ | |
| 6 mois | 27.06€ | |
| 1 an | 54.12€ | |

**Pour ce projet (2-3 mois) :** ~10€ total

---

## ✅ Checklist Finale

- [ ] VPS créé et accessible via SSH
- [ ] Script deploy-vps.sh exécuté avec succès
- [ ] Bitcoin Core synced (getblockchaininfo → initialblockdownload: false)
- [ ] Testcoins reçus (getbalance > 0)
- [ ] Lightning démarré (getinfo retourne le node ID)
- [ ] Serveur LNURL actif (systemctl status lnurl-server)
- [ ] Endpoints testés (curl retourne du JSON)
- [ ] Prof informé par email avec l'IP publique
- [ ] Infos sauvegardées localement
- [ ] lnurl-info.txt supprimé du serveur

---

## 🎉 Terminé !

Ton infrastructure est maintenant déployée en production sur un VPS Linux natif.

**Avantages :**
✅ Stable 24/7 (plus de problème WSL)  
✅ Accessible depuis n'importe où  
✅ Le prof peut tester quand il veut  
✅ Compétence DevOps acquise  

**Prochaines étapes :**
- Attendre les tests du prof
- Éventuellement ouvrir un canal avec le nœud du prof
- Surveiller les logs pour voir les requêtes entrantes

Bon courage ! 🚀
