# 🛠️ Scripts de Gestion des Services

Ce dossier contient des scripts bash pour gérer facilement le backend Strapi et le frontend React Router.

## 📜 Scripts Disponibles

### 🛑 `stop-services.sh`
**Arrête tous les services et libère les ports**

```bash
./stop-services.sh
```

**Fonctionnalités :**
- ✅ Arrête tous les processus npm dev (frontend)
- ✅ Arrête tous les processus Strapi (backend)
- ✅ Libère les ports 1440 et 5173
- ✅ Nettoyage des processus zombie
- ✅ Vérification finale des ports
- ✅ Option de redémarrage automatique

---

### 🚀 `start-services.sh`
**Démarre le backend puis le frontend**

```bash
./start-services.sh
```

**Fonctionnalités :**
- ✅ Vérification des prérequis (ports libres)
- ✅ Installation automatique des dépendances si nécessaire
- ✅ Démarrage du backend Strapi (port 1440)
- ✅ Attente que Strapi soit prêt
- ✅ Démarrage du frontend Vite (port 5173)
- ✅ Sauvegarde des PIDs dans `logs/`
- ✅ Création des logs séparés

---

### 🔄 `restart-services.sh`
**Redémarre complètement les services**

```bash
./restart-services.sh
```

**Fonctionnalités :**
- ✅ Exécute `stop-services.sh`
- ✅ Pause de stabilisation
- ✅ Exécute `start-services.sh`

---

### 📊 `status-services.sh`
**Vérifie l'état des services**

```bash
./status-services.sh
```

**Fonctionnalités :**
- ✅ État des ports 1440 et 5173
- ✅ Processus en cours d'exécution
- ✅ Test de connectivité des services
- ✅ Vérification des logs
- ✅ État des PIDs sauvegardés

## 🗂️ Structure des Logs

```
logs/
├── backend.log          # Logs du backend Strapi
├── frontend.log         # Logs du frontend Vite
├── strapi-monitor.log   # Logs du monitoring Strapi
├── strapi-errors.log    # Logs d'erreurs critiques
├── backend.pid          # PID du processus backend
├── frontend.pid         # PID du processus frontend
├── monitor.pid          # PID du processus monitoring
├── backend-access.log   # Logs d'accès API backend
├── frontend-access.log  # Logs d'accès frontend
└── diagnostic-*.txt     # Rapports de diagnostic
```

### 🔍 Scripts de Monitoring Avancé

#### `monitor-strapi.sh`
**Surveillance automatique de Strapi avec redémarrage intelligent**

```bash
./monitor-strapi.sh monitor    # Monitoring continu
./monitor-strapi.sh check      # Vérification ponctuelle
./monitor-strapi.sh restart    # Redémarrage forcé
./monitor-strapi.sh stats      # Statistiques
./monitor-strapi.sh logs       # Afficher les logs
```

**Fonctionnalités :**
- ✅ Surveillance de la santé de Strapi (HTTP, API, mémoire)
- ✅ Redémarrage automatique en cas de problème
- ✅ Détection des erreurs React/Context
- ✅ Monitoring de l'utilisation mémoire
- ✅ Logs détaillés avec timestamps
- ✅ Service systemd pour démarrage automatique

#### `diagnose-strapi.sh`
**Diagnostic avancé pour identifier les problèmes**

```bash
./diagnose-strapi.sh full      # Diagnostic complet
./diagnose-strapi.sh react     # Erreurs React/Context
./diagnose-strapi.sh memory    # Analyse mémoire
./diagnose-strapi.sh network   # Test connectivité
```

**Fonctionnalités :**
- ✅ Détection erreurs "useContext" et React
- ✅ Analyse utilisation mémoire et fuites
- ✅ Vérification dépendances Node.js
- ✅ Test configuration Vite
- ✅ Génération de rapports détaillés

#### `capture-client-errors.sh`
**Capture et analyse des erreurs côté client (navigateur)**

```bash
./capture-client-errors.sh menu        # Menu interactif
./capture-client-errors.sh test-local  # Tester admin local
./capture-client-errors.sh test-prod   # Tester admin production
./capture-client-errors.sh analyze     # Analyser logs existants
```

**Fonctionnalités :**
- ✅ Capture d'erreurs JavaScript côté client
- ✅ Détection spécifique des erreurs useContext
- ✅ Test automatisé avec Puppeteer (optionnel)
- ✅ Génération de rapports d'erreur détaillés
- ✅ Solutions automatiques recommandées
- ✅ Analyse des patterns d'erreur React

#### `view-logs.sh`
**Interface de visualisation des logs en temps réel**

```bash
./view-logs.sh    # Interface interactive
```

**Fonctionnalités :**
- ✅ Visualisation logs en temps réel (tail -f)
- ✅ Recherche dans tous les logs
- ✅ Statistiques et analyse d'erreurs
- ✅ Navigation simple entre les logs
- ✅ Détection automatique d'erreurs critiques

#### `init-logs.sh`
**Initialisation de la structure complète des logs**

```bash
./init-logs.sh
```

**Fonctionnalités :**
- ✅ Création automatique de tous les fichiers de logs
- ✅ Configuration de logrotate
- ✅ Script de nettoyage automatique
- ✅ Tâche cron pour maintenance
- ✅ Documentation complète des logs

## 🎯 Utilisation Typique

### Premier démarrage
```bash
# Démarrer les services
./start-services.sh
```

### Développement quotidien
```bash
# Vérifier l'état
./status-services.sh

# Redémarrer si nécessaire
./restart-services.sh

# Arrêter en fin de journée
./stop-services.sh
```

### En cas de problème useContext/React
```bash
# Diagnostiquer l'erreur
./diagnose-strapi.sh react

# Capturer l'erreur côté client
./capture-client-errors.sh test-prod

# Créer un rapport détaillé
./capture-client-errors.sh report "message d'erreur"

# Redémarrage intelligent
./monitor-strapi.sh restart

# Si persistant : reconstruire
cd backend && rm -rf node_modules && npm install
```

## 📝 Commandes Utiles

### Logs en temps réel et analyse
```bash
# Interface interactive de logs
./view-logs.sh

# Backend en temps réel
tail -f logs/backend.log

# Frontend en temps réel  
tail -f logs/frontend.log

# Monitoring Strapi
tail -f logs/strapi-monitor.log

# Tous les logs
tail -f logs/*.log

# Rechercher des erreurs
grep -i "error\|exception" logs/*.log

# Erreurs useContext spécifiquement
grep -i "useContext\|Cannot read properties of null" logs/*.log

# Statistiques des logs
wc -l logs/*.log
```

### Vérification manuelle des ports
```bash
# Voir qui utilise les ports
lsof -i:1440
lsof -i:5173

# Tuer un processus spécifique
kill <PID>
```

### Nettoyage manuel
```bash
# Tuer tous les processus npm
pkill -f npm

# Tuer tous les processus node du projet
pkill -f "node.*myblog"
```

## 🔧 Personnalisation

### Changer les ports
Modifiez les variables dans les scripts :
- `1440` pour le backend Strapi
- `5173` pour le frontend Vite

### Ajouter d'autres services
Ajoutez des fonctions dans `start-services.sh` et `stop-services.sh` pour d'autres services (base de données, Redis, etc.)

### Notifications
Les scripts utilisent des couleurs pour les messages :
- 🔵 Bleu : Information
- 🟢 Vert : Succès
- 🟡 Jaune : Avertissement
- 🔴 Rouge : Erreur

## ⚡ Conseils de Performance

1. **Utilisez `restart-services.sh`** plutôt que d'arrêter/démarrer manuellement
2. **Vérifiez les logs** si un service ne démarre pas correctement
3. **Nettoyez régulièrement** les fichiers de logs s'ils deviennent trop volumineux
4. **Surveillez la mémoire** avec `./status-services.sh`

## 🐛 Dépannage

### Service ne démarre pas
```bash
# Vérifier les logs
cat logs/backend.log
cat logs/frontend.log

# Vérifier les ports
lsof -i:1440
lsof -i:5173

# Nettoyage forcé
./stop-services.sh
```

### Port déjà utilisé
```bash
# Identifier le processus
lsof -i:PORT_NUMBER

# Tuer le processus
kill -9 <PID>
```

### Processus zombie
```bash
# Nettoyage complet
./stop-services.sh

# Vérification
ps aux | grep -E "(npm|node|strapi)" | grep -v grep
```

## 📚 Liens Utiles

- [Documentation Strapi](https://docs.strapi.io/)
- [Documentation Vite](https://vitejs.dev/)
- [Guide Bash](https://www.gnu.org/software/bash/manual/)

---

💡 **Astuce** : Ajoutez ces scripts à votre PATH ou créez des alias pour y accéder de n'importe où :

```bash
# Dans votre ~/.bashrc ou ~/.zshrc
alias blog-start='cd /path/to/myblog && ./start-services.sh'
alias blog-stop='cd /path/to/myblog && ./stop-services.sh'
alias blog-status='cd /path/to/myblog && ./status-services.sh'
alias blog-restart='cd /path/to/myblog && ./restart-services.sh'
```
