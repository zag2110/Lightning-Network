# 3 Options de Déploiement - Analyse

Le prof propose 3 options. Voici une analyse pour t'aider à choisir :

---

## Option 1 : VPS Personnel ou Cloud 🥇

### ✅ Recommandé

**Ce que c'est :**
- Louer un serveur Linux dans le cloud (Hetzner, DigitalOcean, Oracle, etc.)
- Déployer ton stack LNURL dessus
- Accessible 24/7 depuis n'importe où

### Avantages
- ✅ **Résout le problème WSL** définitivement (Linux natif)
- ✅ **Disponible 24/7** - Le prof teste quand il veut
- ✅ **Pas de config réseau** - IP publique directe
- ✅ **Stable** - Pas de crash de plugins
- ✅ **Compétence valorisée** - Utile pour ta carrière
- ✅ **Scripts fournis** - Installation automatique en 1h

### Coût
- **Hetzner Cloud CPX11 :** 4.51€/mois (~10€ pour le projet)
- **Oracle Cloud Free Tier :** 0€ (gratuit à vie)

### Difficulté
⭐⭐☆☆☆ (Facile avec le script fourni)

### Temps
- Création VPS : 5 min
- Installation automatique : 1h (principalement sync Bitcoin)
- Configuration finale : 10 min

### Fichiers fournis
- ✅ **GUIDE-DEPLOIEMENT-VPS.md** - Guide complet détaillé
- ✅ **DEPLOIEMENT-RAPIDE.md** - Procédure étape par étape
- ✅ **deploy-vps.sh** - Script d'installation automatique

### Action immédiate
```bash
# 1. Créer un compte sur Hetzner : https://www.hetzner.com/cloud
# 2. Créer un VPS Ubuntu 24.04 (CPX11)
# 3. Se connecter : ssh root@<IP_VPS>
# 4. Lancer le script : ./deploy-vps.sh
```

---

## Option 2 : Acheter un VPS (Conseil du Prof) 💡

### Le prof dit :
> "you don't [have a VPS] : do it, that's always useful to have"
> "You can buy a VPS for less than the cost of a drink in Paris"
> "I strongly advise you to have a home server or a VPS always handy, 
>  that's really nice to have skills and it often comes handy when you 
>  don't expect it"

### Interprétation
C'est **la même que l'Option 1** mais le prof insiste sur :
- C'est une **compétence importante** à avoir
- C'est **pas cher** (moins qu'un verre à Paris = 4-8€)
- C'est **toujours utile** dans ta carrière tech
- Tu devrais le faire **même si ce n'est pas pour ce projet**

### Mon conseil
Le prof a raison ! Avoir son propre VPS c'est :
- Apprendre Docker, Nginx, systemd, SSH
- Héberger tes projets persos
- Avoir un serveur de dev accessible partout
- Tester des technos sans polluer ton PC

**→ Choisis l'Option 1 = Option 2** (c'est pareil)

---

## Option 3 : Laptop + Redirection de Port ⚠️

### Ce que c'est
- Garder ton setup WSL actuel
- Configurer ta box internet pour rediriger le port 3000 vers ton PC
- Convenir d'une date/heure où ton PC sera allumé et en ligne
- Le prof teste à ce moment-là

### Avantages
- ✅ **Gratuit** (pas de VPS)
- ✅ **Pas de nouveau setup** (garde WSL)

### Inconvénients
- ❌ **Problème de stabilité Lightning persiste** (plugins crashent)
- ❌ **Doit rester allumé** pendant les tests
- ❌ **Configuration box complexe** (dépend du FAI)
- ❌ **Horaires contraints** (doit coordonner avec le prof)
- ❌ **IP dynamique ?** (peut changer)
- ❌ **Pas flexible** pour le prof
- ❌ **Risque de sécurité** (ouvrir ton réseau local)

### Difficulté
⭐⭐⭐⭐☆ (Difficile - dépend de ta box/FAI)

### Quand choisir cette option
- Tu ne peux vraiment pas payer 5-10€
- Tu n'as pas de carte bancaire
- Le délai est très court

### Procédure

#### 1. Redirection de Port sur la Box

**Exemples selon FAI :**

**Free (Freebox) :**
```
1. Aller sur https://subscribe.free.fr/login/
2. Ma Freebox > Paramétrer mon routeur
3. Redirections de ports
4. Ajouter :
   - Port externe : 3000
   - Port interne : 3000
   - IP destination : <IP_DE_TON_PC> (voir ipconfig)
   - Protocole : TCP
```

**Orange (Livebox) :**
```
1. http://192.168.1.1
2. Avancé > NAT/PAT
3. Ajouter une règle :
   - Application : LNURL
   - Port externe : 3000
   - Port interne : 3000
   - IP : <IP_DE_TON_PC>
   - Protocole : TCP
```

**SFR/RED :**
```
1. http://192.168.1.1
2. Réseau > NAT
3. Créer une règle
```

**Bouygues :**
```
1. http://192.168.1.254
2. Advanced > NAT
3. Add rule
```

#### 2. Trouver ton IP Publique

```bash
curl ifconfig.me
```

#### 3. Script de Démarrage Fiable

Créer un script qui maintient Lightning et le serveur en vie :

```bash
#!/bin/bash
# keep-alive.sh

while true; do
    # Vérifier Lightning
    if ! pgrep lightningd > /dev/null; then
        echo "[$(date)] Redémarrage Lightning..."
        pkill -9 lightningd
        rm -f ~/.lightning/testnet4/lightning-rpc
        sleep 2
        lightningd --network=testnet4 --daemon
        sleep 15
    fi
    
    # Vérifier Serveur
    if ! pgrep -f "target/release/server" > /dev/null; then
        echo "[$(date)] Redémarrage serveur..."
        cd ~/LN_version_2/lnurl-server
        ./target/release/server > /tmp/server.log 2>&1 &
        sleep 5
    fi
    
    sleep 10
done
```

Lancer :
```bash
cd "/mnt/c/Sacha/Cours/LN version 2"
chmod +x keep-alive.sh
./keep-alive.sh > /tmp/keep-alive.log 2>&1 &
```

#### 4. Email au Prof

```
Objet : Projet LNURL - Démo sur Laptop (Redirection de Port)

Bonjour,

J'ai configuré mon laptop avec redirection de port pour le test LNURL.

En raison du problème de stabilité Lightning dans WSL (plugins qui crashent),
j'ai mis en place un script de surveillance qui maintient les services actifs.

Informations d'accès :
- IP publique : <TON_IP_PUBLIQUE>
- Port : 3000
- Endpoints : http://<TON_IP>:3000/request-channel

Proposition de créneaux où je m'engage à avoir la machine en ligne :
- [DATE 1] de [HEURE] à [HEURE]
- [DATE 2] de [HEURE] à [HEURE]
- [DATE 3] de [HEURE] à [HEURE]

Le système a une stabilité d'environ 15-30 secondes par cycle de redémarrage,
avec un script de surveillance qui relance automatiquement en cas de crash.

Si cette approche n'est pas satisfaisante, je peux déployer sur un VPS 
(temps nécessaire : ~2 jours).

Cordialement,
Sacha
```

---

## 🎯 Comparaison Finale

| Critère | Option 1: VPS | Option 3: Laptop |
|---------|---------------|------------------|
| **Coût** | 5-10€ | Gratuit |
| **Stabilité** | ✅ Excellente | ❌ Problématique (WSL) |
| **Disponibilité** | ✅ 24/7 | ⚠️ Horaires contraints |
| **Configuration** | ⭐⭐ Facile | ⭐⭐⭐⭐ Complexe |
| **Flexibilité prof** | ✅ Teste quand il veut | ❌ Doit coordonner |
| **Sécurité** | ✅ Isolé | ⚠️ Ouvre ton réseau |
| **Compétences acquises** | ✅ DevOps, Cloud | ⚠️ Réseau local |
| **Temps setup** | 1h | Variable (1h-4h) |
| **Recommandation prof** | ✅✅✅ Fortement | ⚠️ Si vraiment pas le choix |

---

## 🏆 Ma Recommandation

### Pour Toi : Option 1 (VPS) 🥇

**Raisons :**
1. **Résout ton problème** de stabilité Lightning définitivement
2. **Le prof le recommande fortement** ("I strongly advise")
3. **Coût négligeable** (4.51€/mois = 1 café)
4. **Gain de temps** (script automatique vs debug réseau)
5. **Compétence valorisée** sur un CV
6. **Flexibilité maximale** pour le prof
7. **Moins de stress** (pas besoin de coordonner horaires)

### Si Vraiment Impossible : Option 3 (Laptop)

**Mais seulement si :**
- Budget vraiment serré (pas même 5€)
- Délai très court (< 24h)
- Tu es à l'aise avec la config réseau

**Et accepte que :**
- Le prof devra coordonner avec toi
- Lightning peut crasher pendant le test
- Tu devras redémarrer plusieurs fois

---

## 💡 Mon Conseil Personnel

Le prof a raison : **avoir un VPS est une compétence fondamentale**.

**Investis 5€ maintenant, tu vas :**
1. Résoudre ton projet LNURL proprement
2. Apprendre Docker, systemd, SSH, firewall
3. Avoir un serveur pour tes futurs projets
4. Pouvoir mettre "Déploiement Cloud" sur ton CV

**Providers recommandés :**
- **Budget étudiant :** Hetzner (4.51€/mois)
- **Gratuit :** Oracle Cloud Free Tier
- **GitHub Student :** DigitalOcean (200$ offerts)

---

## 📋 Action Immédiate

**Si tu choisis le VPS (Recommandé) :**
```bash
# Suivre DEPLOIEMENT-RAPIDE.md
# Temps total : ~1h30
```

**Si tu choisis le Laptop :**
```bash
# 1. Configurer la redirection de port sur ta box
# 2. Lancer le script keep-alive.sh
# 3. Envoyer l'email au prof avec créneaux
```

---

## 🆘 Besoin d'Aide ?

Si tu as des questions sur le déploiement VPS :
1. Lire **GUIDE-DEPLOIEMENT-VPS.md** (très détaillé)
2. Lire **DEPLOIEMENT-RAPIDE.md** (étape par étape)
3. Lancer **deploy-vps.sh** (fait tout automatiquement)

Le prof a raison : **"that's always useful to have"** ! 🚀
