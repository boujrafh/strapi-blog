#!/bin/bash

# 🛑 Script pour arrêter toutes les applications et libérer les ports
# Utile avant de redémarrer le backend et frontend

echo "🛑 Arrêt des applications blog"
echo "=============================="

# Configuration des logs
LOG_DIR="/home/myblog/logs"
SYSTEM_LOG="$LOG_DIR/system.log"

# S'assurer que le dossier logs existe
mkdir -p "$LOG_DIR"

# Fonction pour logger avec timestamp
log_to_file() {
    local logfile=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$logfile"
}

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés ET les logger
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log_to_file "$SYSTEM_LOG" "STOP-INFO: $1"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_to_file "$SYSTEM_LOG" "STOP-SUCCESS: $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_to_file "$SYSTEM_LOG" "STOP-WARNING: $1"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    log_to_file "$SYSTEM_LOG" "STOP-ERROR: $1"
}

# Fonction pour tuer un processus par nom
kill_process_by_name() {
    local process_name=$1
    local pids=$(pgrep -f "$process_name")
    
    if [ -n "$pids" ]; then
        log_info "Arrêt des processus: $process_name"
        echo "$pids" | while read pid; do
            log_info "  - Arrêt du PID: $pid"
            kill -TERM "$pid" 2>/dev/null
        done
        sleep 2
        
        # Vérifier si des processus persistent
        local remaining_pids=$(pgrep -f "$process_name")
        if [ -n "$remaining_pids" ]; then
            log_warning "Processus persistants détectés, force kill..."
            echo "$remaining_pids" | while read pid; do
                kill -KILL "$pid" 2>/dev/null
            done
        fi
        log_success "Processus $process_name arrêtés"
    else
        log_info "Aucun processus $process_name en cours"
    fi
}

# Fonction pour libérer un port spécifique
free_port() {
    local port=$1
    local pids=$(lsof -ti:$port 2>/dev/null)
    
    if [ -n "$pids" ]; then
        log_info "Libération du port $port"
        echo "$pids" | while read pid; do
            local process_name=$(ps -p $pid -o comm= 2>/dev/null)
            log_info "  - Arrêt du processus $process_name (PID: $pid) sur le port $port"
            kill -TERM "$pid" 2>/dev/null
        done
        sleep 1
        
        # Vérifier si le port est toujours occupé
        local remaining_pids=$(lsof -ti:$port 2>/dev/null)
        if [ -n "$remaining_pids" ]; then
            log_warning "Port $port toujours occupé, force kill..."
            echo "$remaining_pids" | while read pid; do
                kill -KILL "$pid" 2>/dev/null
            done
        fi
        log_success "Port $port libéré"
    else
        log_info "Port $port déjà libre"
    fi
}

echo ""
log_info "🔍 Vérification des processus en cours..."

# Afficher les processus actuels
echo ""
echo "📊 Processus npm/node/strapi actuels:"
ps aux | grep -E "(npm|node|strapi)" | grep -v grep | while read line; do
    echo "  $line"
done

echo ""
echo "📊 Ports occupés (1440, 5173):"
lsof -i:1440 2>/dev/null | head -1
lsof -i:1440 2>/dev/null | tail -n +2 | while read line; do
    echo "  Port 1440: $line"
done

lsof -i:5173 2>/dev/null | head -1
lsof -i:5173 2>/dev/null | tail -n +2 | while read line; do
    echo "  Port 5173: $line"
done

echo ""
log_info "🛑 Début de l'arrêt des services..."

# 1. Arrêter les processus npm dev (frontend)
echo ""
log_info "1️⃣ Arrêt des serveurs de développement frontend..."
kill_process_by_name "npm.*dev"
kill_process_by_name "vite"

# 2. Arrêter les processus Strapi (backend)
echo ""
log_info "2️⃣ Arrêt des serveurs Strapi..."
kill_process_by_name "strapi.*develop"
kill_process_by_name "strapi.*start"
kill_process_by_name "npm.*start"

# 3. Arrêter tous les processus Node.js restants liés au projet
echo ""
log_info "3️⃣ Arrêt des processus Node.js du projet..."
kill_process_by_name "node.*myblog"
kill_process_by_name "node.*1440"
kill_process_by_name "node.*5173"

# 4. Libérer les ports spécifiques
echo ""
log_info "4️⃣ Libération des ports..."
free_port 1440  # Port Strapi
free_port 5173  # Port Vite/Frontend

# 5. Nettoyage des processus zombie
echo ""
log_info "5️⃣ Nettoyage des processus zombie..."
pkill -f "defunct" 2>/dev/null || true

# 6. Vérification finale
echo ""
log_info "🔍 Vérification finale..."
sleep 1

echo ""
echo "📊 État final des ports:"
port_1440_status=$(lsof -i:1440 2>/dev/null)
port_5173_status=$(lsof -i:5173 2>/dev/null)

if [ -z "$port_1440_status" ]; then
    log_success "Port 1440 (Strapi) : LIBRE"
else
    log_error "Port 1440 (Strapi) : OCCUPÉ"
    echo "$port_1440_status"
fi

if [ -z "$port_5173_status" ]; then
    log_success "Port 5173 (Frontend) : LIBRE"
else
    log_error "Port 5173 (Frontend) : OCCUPÉ"
    echo "$port_5173_status"
fi

echo ""
echo "📊 Processus restants liés au projet:"
remaining_processes=$(ps aux | grep -E "(npm|node|strapi)" | grep -v grep | grep -E "(myblog|1440|5173|develop|dev)")
if [ -z "$remaining_processes" ]; then
    log_success "Aucun processus lié au projet en cours"
else
    log_warning "Processus restants détectés:"
    echo "$remaining_processes"
fi

echo ""
log_success "🎉 Arrêt terminé !"
echo ""
echo "💡 Vous pouvez maintenant relancer les services:"
echo "   🔹 Backend:  cd backend && npm run develop"
echo "   🔹 Frontend: cd frontend && npm run dev"
echo ""

# Option pour redémarrer automatiquement
read -p "🤔 Voulez-vous redémarrer automatiquement les services ? (y/N): " restart_services

if [[ $restart_services =~ ^[Yy]$ ]]; then
    echo ""
    log_info "🚀 Redémarrage des services..."
    
    # Démarrer le backend
    echo ""
    log_info "🔹 Démarrage du backend Strapi..."
    cd backend
    npm run develop &
    backend_pid=$!
    log_success "Backend démarré (PID: $backend_pid)"
    
    # Attendre un peu puis démarrer le frontend
    echo ""
    log_info "⏳ Attente 5 secondes avant de démarrer le frontend..."
    sleep 5
    
    log_info "🔹 Démarrage du frontend..."
    cd ../frontend
    npm run dev &
    frontend_pid=$!
    log_success "Frontend démarré (PID: $frontend_pid)"
    
    echo ""
    log_success "🎉 Services redémarrés !"
    echo ""
    echo "📊 Nouveaux processus:"
    echo "   🔹 Backend Strapi: PID $backend_pid (port 1440)"
    echo "   🔹 Frontend Vite: PID $frontend_pid (port 5173)"
    echo ""
    echo "🌐 URLs d'accès:"
    echo "   🔹 Frontend local: http://localhost:5173"
    echo "   🔹 Backend local: http://localhost:1440/admin"
    echo "   🔹 Frontend prod: https://blog.votre-domaine.com"
    echo "   🔹 Backend prod: https://cms.votre-domaine.com/admin"
fi
