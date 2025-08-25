#!/bin/bash

# 🔍 Script de monitoring avancé pour Strapi
# Surveille la santé de Strapi et redémarre automatiquement si nécessaire

echo "🔍 Monitoring Strapi - Démarrage"
echo "================================"

# Configuration
STRAPI_PORT=1440
STRAPI_URL="http://localhost:$STRAPI_PORT"
STRAPI_ADMIN_URL="$STRAPI_URL/admin"
LOG_DIR="/home/myblog/logs"
MONITOR_LOG="$LOG_DIR/strapi-monitor.log"
ERROR_LOG="$LOG_DIR/strapi-errors.log"
CHECK_INTERVAL=30  # Vérification toutes les 30 secondes
MAX_FAILURES=3     # Redémarrer après 3 échecs consécutifs
MEMORY_THRESHOLD=80 # Redémarrer si mémoire > 80%

# Créer le dossier logs s'il n'existe pas
mkdir -p "$LOG_DIR"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Fonction pour logger avec timestamp
log_with_timestamp() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$MONITOR_LOG"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log_with_timestamp "INFO" "$1"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_with_timestamp "SUCCESS" "$1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_with_timestamp "WARNING" "$1"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    log_with_timestamp "ERROR" "$1"
}

log_critical() {
    echo -e "${RED}🚨 $1${NC}"
    log_with_timestamp "CRITICAL" "$1"
}

# Variables globales pour le suivi
FAILURE_COUNT=0
LAST_RESTART=$(date +%s)
RESTART_COUNT=0

# Fonction pour vérifier si Strapi répond
check_strapi_health() {
    local health_status="OK"
    local issues=()
    
    # 1. Vérifier si le processus existe
    local strapi_pid=$(pgrep -f "strapi.*develop")
    if [ -z "$strapi_pid" ]; then
        health_status="CRITICAL"
        issues+=("Processus Strapi non trouvé")
        return 1
    fi
    
    # 2. Vérifier si le port répond
    if ! nc -z localhost $STRAPI_PORT 2>/dev/null; then
        health_status="CRITICAL"
        issues+=("Port $STRAPI_PORT non accessible")
        return 1
    fi
    
    # 3. Vérifier la réponse HTTP
    local http_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$STRAPI_URL" 2>/dev/null)
    if [ "$http_response" != "302" ] && [ "$http_response" != "200" ]; then
        health_status="ERROR"
        issues+=("Réponse HTTP invalide: $http_response")
        return 1
    fi
    
    # 4. Vérifier l'API
    local api_response=$(curl -s --max-time 10 "$STRAPI_URL/api/posts" 2>/dev/null)
    if ! echo "$api_response" | jq . >/dev/null 2>&1; then
        health_status="ERROR"
        issues+=("API ne retourne pas de JSON valide")
        return 1
    fi
    
    # 5. Vérifier l'utilisation mémoire
    local memory_usage=$(ps -p $strapi_pid -o %mem --no-headers | tr -d ' ')
    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
        health_status="WARNING"
        issues+=("Utilisation mémoire élevée: ${memory_usage}%")
        log_warning "Utilisation mémoire élevée: ${memory_usage}%"
    fi
    
    # 6. Vérifier les erreurs dans les logs
    if [ -f "/home/myblog/backend/logs/strapi.log" ]; then
        local recent_errors=$(tail -50 /home/myblog/backend/logs/strapi.log | grep -i "error\|exception\|fatal" | wc -l)
        if [ "$recent_errors" -gt 5 ]; then
            health_status="WARNING"
            issues+=("$recent_errors erreurs récentes dans les logs")
        fi
    fi
    
    if [ "$health_status" = "OK" ]; then
        return 0
    else
        log_error "Problèmes détectés: ${issues[*]}"
        return 1
    fi
}

# Fonction pour redémarrer Strapi
restart_strapi() {
    log_critical "🔄 Redémarrage de Strapi requis (tentative #$((RESTART_COUNT + 1)))"
    
    # Sauvegarder les logs actuels
    if [ -f "/home/myblog/backend/logs/strapi.log" ]; then
        cp "/home/myblog/backend/logs/strapi.log" "$ERROR_LOG.$(date +%s)"
    fi
    
    # Arrêter Strapi proprement
    log_info "Arrêt de Strapi..."
    pkill -f "strapi.*develop" || true
    sleep 3
    
    # Force kill si nécessaire
    pkill -9 -f "strapi.*develop" || true
    
    # Libérer le port
    local port_pids=$(lsof -ti:$STRAPI_PORT 2>/dev/null)
    if [ -n "$port_pids" ]; then
        log_warning "Libération forcée du port $STRAPI_PORT"
        echo "$port_pids" | xargs kill -9 2>/dev/null || true
    fi
    
    sleep 2
    
    # Redémarrer Strapi
    log_info "Démarrage de Strapi..."
    cd /home/myblog/backend
    
    # Créer le dossier logs s'il n'existe pas
    mkdir -p logs
    
    # Démarrer en arrière-plan avec logs
    nohup npm run develop > logs/strapi.log 2>&1 &
    local new_pid=$!
    
    # Attendre le démarrage
    log_info "Attente du démarrage (PID: $new_pid)..."
    sleep 10
    
    # Vérifier que le démarrage a réussi
    local startup_attempts=0
    while [ $startup_attempts -lt 12 ]; do  # 2 minutes max
        if check_strapi_health; then
            log_success "✅ Strapi redémarré avec succès (PID: $new_pid)"
            FAILURE_COUNT=0
            LAST_RESTART=$(date +%s)
            RESTART_COUNT=$((RESTART_COUNT + 1))
            return 0
        fi
        sleep 10
        startup_attempts=$((startup_attempts + 1))
        log_info "Tentative de vérification $startup_attempts/12..."
    done
    
    log_critical "❌ Échec du redémarrage de Strapi"
    return 1
}

# Fonction pour afficher les statistiques
show_stats() {
    local uptime_seconds=$(($(date +%s) - LAST_RESTART))
    local uptime_formatted=$(date -u -d @$uptime_seconds +"%H:%M:%S")
    
    echo ""
    echo "📊 Statistiques Strapi:"
    echo "   🔹 Redémarrages: $RESTART_COUNT"
    echo "   🔹 Échecs consécutifs: $FAILURE_COUNT"
    echo "   🔹 Uptime depuis dernier restart: $uptime_formatted"
    echo "   🔹 Dernier restart: $(date -d @$LAST_RESTART '+%Y-%m-%d %H:%M:%S')"
    
    # Statistiques processus
    local strapi_pid=$(pgrep -f "strapi.*develop")
    if [ -n "$strapi_pid" ]; then
        local memory_usage=$(ps -p $strapi_pid -o %mem --no-headers | tr -d ' ')
        local cpu_usage=$(ps -p $strapi_pid -o %cpu --no-headers | tr -d ' ')
        echo "   🔹 PID: $strapi_pid"
        echo "   🔹 Mémoire: ${memory_usage}%"
        echo "   🔹 CPU: ${cpu_usage}%"
    fi
}

# Gestion des signaux pour arrêt propre
cleanup() {
    log_info "🛑 Arrêt du monitoring Strapi"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Fonction principale de monitoring
main_monitor_loop() {
    log_info "🚀 Démarrage du monitoring Strapi"
    log_info "Configuration:"
    log_info "  - Port: $STRAPI_PORT"
    log_info "  - Intervalle: ${CHECK_INTERVAL}s"
    log_info "  - Seuil d'échecs: $MAX_FAILURES"
    log_info "  - Seuil mémoire: ${MEMORY_THRESHOLD}%"
    
    while true; do
        echo ""
        echo "🔍 Vérification de la santé de Strapi... $(date '+%H:%M:%S')"
        
        if check_strapi_health; then
            log_success "Strapi fonctionne correctement"
            FAILURE_COUNT=0
            show_stats
        else
            FAILURE_COUNT=$((FAILURE_COUNT + 1))
            log_error "Échec de la vérification de santé ($FAILURE_COUNT/$MAX_FAILURES)"
            
            if [ $FAILURE_COUNT -ge $MAX_FAILURES ]; then
                if restart_strapi; then
                    log_success "Redémarrage réussi"
                else
                    log_critical "Échec du redémarrage - intervention manuelle requise"
                    # Attendre plus longtemps avant de réessayer
                    sleep 300
                fi
            fi
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Vérifier les arguments de ligne de commande
case "${1:-monitor}" in
    "monitor"|"start")
        main_monitor_loop
        ;;
    "check")
        echo "🔍 Vérification ponctuelle de Strapi..."
        if check_strapi_health; then
            log_success "Strapi fonctionne correctement"
            show_stats
            exit 0
        else
            log_error "Problèmes détectés avec Strapi"
            exit 1
        fi
        ;;
    "restart")
        echo "🔄 Redémarrage forcé de Strapi..."
        restart_strapi
        ;;
    "stats")
        show_stats
        ;;
    "logs")
        echo "📋 Logs de monitoring:"
        if [ -f "$MONITOR_LOG" ]; then
            tail -50 "$MONITOR_LOG"
        else
            echo "Aucun log trouvé"
        fi
        ;;
    *)
        echo "Usage: $0 {monitor|check|restart|stats|logs}"
        echo ""
        echo "Commandes:"
        echo "  monitor  - Démarrer le monitoring continu (défaut)"
        echo "  check    - Vérification ponctuelle"
        echo "  restart  - Redémarrage forcé"
        echo "  stats    - Afficher les statistiques"
        echo "  logs     - Afficher les logs de monitoring"
        exit 1
        ;;
esac
