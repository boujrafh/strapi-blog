#!/bin/bash

# 📁 Script d'initialisation des logs
# Crée automatiquement la structure de logs pour le monitoring

echo "📁 Initialisation de la structure des logs"
echo "=========================================="

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Créer le dossier logs principal
LOGS_DIR="/home/myblog/logs"

log_info "Création du dossier logs principal..."
mkdir -p "$LOGS_DIR"
log_success "Dossier créé: $LOGS_DIR"

# Créer les fichiers de logs avec en-têtes
create_log_file() {
    local log_file="$1"
    local description="$2"
    
    if [ ! -f "$log_file" ]; then
        cat > "$log_file" << EOF
# =====================================
# $description
# =====================================
# Créé le: $(date)
# Localisation: $log_file
# =====================================

EOF
        log_success "Fichier créé: $(basename "$log_file")"
    else
        log_warning "Fichier existant: $(basename "$log_file")"
    fi
}

# Créer tous les fichiers de logs
echo ""
log_info "Création des fichiers de logs..."

create_log_file "$LOGS_DIR/backend.log" "LOGS BACKEND STRAPI"
create_log_file "$LOGS_DIR/frontend.log" "LOGS FRONTEND REACT ROUTER"
create_log_file "$LOGS_DIR/strapi-monitor.log" "LOGS MONITORING STRAPI"
create_log_file "$LOGS_DIR/strapi-errors.log" "LOGS ERREURS CRITIQUES STRAPI"
create_log_file "$LOGS_DIR/backend-access.log" "LOGS ACCÈS API BACKEND"
create_log_file "$LOGS_DIR/frontend-access.log" "LOGS ACCÈS FRONTEND"
create_log_file "$LOGS_DIR/system.log" "LOGS SYSTÈME GÉNÉRAL"
create_log_file "$LOGS_DIR/performance.log" "LOGS PERFORMANCE ET MÉTRIQUES"

# Créer des fichiers de configuration
echo ""
log_info "Création des fichiers de configuration..."

# Configuration logrotate
cat > "$LOGS_DIR/logrotate.conf" << 'EOF'
# Configuration logrotate pour les logs du blog
/home/myblog/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        # Redémarrer les services si nécessaire
        systemctl reload strapi-monitor 2>/dev/null || true
    endscript
}
EOF

# Script de nettoyage automatique
cat > "$LOGS_DIR/cleanup-logs.sh" << 'EOF'
#!/bin/bash
# Script de nettoyage automatique des logs

LOG_DIR="/home/myblog/logs"
MAX_SIZE="100M"  # Taille maximale par fichier
MAX_AGE=30       # Âge maximum en jours

echo "🧹 Nettoyage automatique des logs..."

# Supprimer les fichiers de plus de 30 jours
find "$LOG_DIR" -name "*.log" -type f -mtime +$MAX_AGE -delete

# Tronquer les fichiers trop volumineux
for logfile in "$LOG_DIR"/*.log; do
    if [ -f "$logfile" ]; then
        size=$(stat -f%z "$logfile" 2>/dev/null || stat -c%s "$logfile" 2>/dev/null)
        max_bytes=$(echo $MAX_SIZE | sed 's/M/*1024*1024/' | bc)
        
        if [ "$size" -gt "$max_bytes" ]; then
            echo "Fichier $logfile trop volumineux ($size bytes), troncature..."
            tail -n 1000 "$logfile" > "$logfile.tmp"
            mv "$logfile.tmp" "$logfile"
        fi
    fi
done

echo "✅ Nettoyage terminé"
EOF

chmod +x "$LOGS_DIR/cleanup-logs.sh"

# README pour les logs
cat > "$LOGS_DIR/README.md" << 'EOF'
# 📁 Dossier Logs

Ce dossier contient tous les logs du système de blog.

## 📂 Structure des fichiers

### Logs de services
- `backend.log` - Logs du backend Strapi
- `frontend.log` - Logs du frontend React Router
- `strapi-monitor.log` - Logs du système de monitoring
- `strapi-errors.log` - Erreurs critiques de Strapi

### Logs d'accès
- `backend-access.log` - Accès à l'API backend
- `frontend-access.log` - Accès au frontend

### Logs système
- `system.log` - Logs système généraux
- `performance.log` - Métriques de performance

### Fichiers de processus
- `*.pid` - Fichiers contenant les PIDs des processus

### Rapports
- `diagnostic-*.txt` - Rapports de diagnostic automatiques

## 🛠️ Commandes utiles

### Consulter les logs
```bash
# Logs en temps réel
tail -f backend.log
tail -f frontend.log

# Rechercher des erreurs
grep -i error *.log
grep -i "useContext" *.log

# Statistiques
wc -l *.log
```

### Nettoyage
```bash
# Nettoyage automatique
./cleanup-logs.sh

# Nettoyage manuel
> backend.log  # Vider un fichier
```

### Analyse
```bash
# Erreurs récentes
grep "$(date +%Y-%m-%d)" *.log | grep -i error

# Utilisation mémoire
grep "Mémoire" strapi-monitor.log | tail -10
```
EOF

log_success "Configuration créée: logrotate.conf"
log_success "Script créé: cleanup-logs.sh"
log_success "Documentation créée: README.md"

# Créer un template pour les logs avec rotation
echo ""
log_info "Configuration des permissions..."
chmod 644 "$LOGS_DIR"/*.log
chmod 755 "$LOGS_DIR"
log_success "Permissions configurées"

# Créer une tâche cron pour le nettoyage automatique
echo ""
log_info "Configuration du nettoyage automatique..."
CRON_JOB="0 2 * * * /home/myblog/logs/cleanup-logs.sh >> /home/myblog/logs/cleanup.log 2>&1"

# Vérifier si la tâche cron existe déjà
if ! crontab -l 2>/dev/null | grep -q "cleanup-logs.sh"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    log_success "Tâche cron ajoutée pour nettoyage automatique (2h du matin)"
else
    log_warning "Tâche cron déjà existante"
fi

echo ""
echo "📊 Résumé de l'initialisation"
echo "============================"
echo ""
echo "📁 Dossier créé: $LOGS_DIR"
echo "📄 Fichiers de logs: $(ls -1 "$LOGS_DIR"/*.log 2>/dev/null | wc -l)"
echo "⚙️  Configuration: logrotate.conf"
echo "🧹 Nettoyage: cleanup-logs.sh"
echo "📋 Documentation: README.md"
echo "🕑 Cron: Nettoyage automatique à 2h"
echo ""

# Afficher la structure créée
log_info "Structure créée:"
ls -la "$LOGS_DIR"

echo ""
log_success "✅ Initialisation des logs terminée !"
echo ""
echo "💡 Commandes utiles:"
echo "   📋 Voir les logs: ls -la $LOGS_DIR"
echo "   🔍 Monitor backend: tail -f $LOGS_DIR/backend.log"
echo "   🔍 Monitor frontend: tail -f $LOGS_DIR/frontend.log"
echo "   🧹 Nettoyer: $LOGS_DIR/cleanup-logs.sh"
echo "   📊 Stats: wc -l $LOGS_DIR/*.log"
