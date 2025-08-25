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
├── backend.log     # Logs du backend Strapi
├── frontend.log    # Logs du frontend Vite
├── backend.pid     # PID du processus backend
└── frontend.pid    # PID du processus frontend
```

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

### En cas de problème
```bash
# Arrêt forcé
./stop-services.sh

# Vérification
./status-services.sh

# Redémarrage propre
./start-services.sh
```

## 📝 Commandes Utiles

### Logs en temps réel
```bash
# Backend
tail -f logs/backend.log

# Frontend
tail -f logs/frontend.log

# Les deux
tail -f logs/*.log
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
