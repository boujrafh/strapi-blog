#!/bin/bash

# 🚀 Script pour démarrer le backend et frontend
# Lance Strapi puis le frontend Vite

echo "🚀 Démarrage des applications blog"
echo "=================================="

# Configuration des logs
LOG_DIR="/home/myblog/logs"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
SYSTEM_LOG="$LOG_DIR/system.log"
PERFORMANCE_LOG="$LOG_DIR/performance.log"

# S'assurer que le dossier logs existe
mkdir -p "$LOG_DIR"

# Fonction pour logger avec timestamp
log_to_file() {
    local logfile=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$logfile"
}

# Fonction pour logger les métriques de performance
log_performance() {
    local service=$1
    local pid=$2
    local port=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        local memory_usage=$(ps -p "$pid" -o %mem --no-headers | tr -d ' ')
        local cpu_usage=$(ps -p "$pid" -o %cpu --no-headers | tr -d ' ')
        echo "[$timestamp] $service (PID:$pid, Port:$port) - CPU:${cpu_usage}% MEM:${memory_usage}%" >> "$PERFORMANCE_LOG"
    fi
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
    log_to_file "$SYSTEM_LOG" "INFO: $1"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_to_file "$SYSTEM_LOG" "SUCCESS: $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_to_file "$SYSTEM_LOG" "WARNING: $1"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    log_to_file "$SYSTEM_LOG" "ERROR: $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    log_error "Dossiers backend ou frontend non trouvés !"
    log_info "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Fonction pour vérifier si un port est libre
check_port() {
    local port=$1
    local process_info=$(lsof -i:$port 2>/dev/null)
    
    if [ -n "$process_info" ]; then
        return 1  # Port occupé
    else
        return 0  # Port libre
    fi
}

# Fonction pour attendre qu'un service soit prêt
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    log_info "⏳ Attente du démarrage de $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            log_success "$service_name prêt !"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_warning "$service_name prend plus de temps que prévu..."
    return 1
}

echo ""
log_info "🔍 Vérification des prérequis..."

# Vérifier les ports
echo ""
log_info "📊 Vérification des ports..."

if ! check_port 1440; then
    log_error "Port 1440 (Strapi) déjà occupé !"
    log_info "Processus sur le port 1440:"
    lsof -i:1440
    echo ""
    log_info "💡 Utilisez './stop-services.sh' pour libérer les ports"
    exit 1
else
    log_success "Port 1440 (Strapi) libre"
fi

if ! check_port 5173; then
    log_error "Port 5173 (Frontend) déjà occupé !"
    log_info "Processus sur le port 5173:"
    lsof -i:5173
    echo ""
    log_info "💡 Utilisez './stop-services.sh' pour libérer les ports"
    exit 1
else
    log_success "Port 5173 (Frontend) libre"
fi

# Vérifier les dépendances
echo ""
log_info "📦 Vérification des dépendances..."

if [ ! -d "backend/node_modules" ]; then
    log_warning "Dépendances backend manquantes"
    log_info "Installation des dépendances backend..."
    cd backend && npm install
    cd ..
fi

if [ ! -d "frontend/node_modules" ]; then
    log_warning "Dépendances frontend manquantes"
    log_info "Installation des dépendances frontend..."
    cd frontend && npm install
    cd ..
fi

log_success "Dépendances vérifiées"

# Démarrer le backend
echo ""
log_info "🔹 Démarrage du backend Strapi..."
log_info "   📍 Répertoire: ./backend"
log_info "   🌐 Port: 1440"
log_info "   📝 Mode: develop"

log_to_file "$BACKEND_LOG" "=== DÉMARRAGE BACKEND STRAPI ==="
log_to_file "$BACKEND_LOG" "Répertoire: $(pwd)/backend"
log_to_file "$BACKEND_LOG" "Port: 1440"
log_to_file "$BACKEND_LOG" "Mode: develop"

cd backend

# Vérifier que les fichiers nécessaires existent
if [ ! -f "package.json" ]; then
    log_error "package.json non trouvé dans le dossier backend !"
    log_to_file "$BACKEND_LOG" "ERREUR: package.json non trouvé"
    exit 1
fi

# Vérifier et installer les dépendances si nécessaire
if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
    log_warning "Dépendances manquantes, installation..."
    log_to_file "$BACKEND_LOG" "Installation des dépendances NPM..."
    npm install >> "$BACKEND_LOG" 2>&1
    log_to_file "$BACKEND_LOG" "Dépendances installées"
fi

# Démarrer Strapi en arrière-plan avec logs détaillés
log_to_file "$BACKEND_LOG" "Commande: npm run develop"
npm run develop >> "$BACKEND_LOG" 2>&1 &
backend_pid=$!

log_to_file "$BACKEND_LOG" "Processus Strapi démarré (PID: $backend_pid)"
log_to_file "$SYSTEM_LOG" "Backend Strapi démarré (PID: $backend_pid)"

cd ..

log_success "Backend Strapi lancé (PID: $backend_pid)"
log_info "📝 Logs backend: tail -f logs/backend.log"

# Créer le dossier logs s'il n'existe pas
mkdir -p logs

# Attendre que Strapi soit prêt
echo ""
wait_for_service "http://localhost:1440" "Strapi"

# Démarrer le frontend
echo ""
log_info "🔹 Démarrage du frontend Vite..."
log_info "   📍 Répertoire: ./frontend"
log_info "   🌐 Port: 5173"
log_info "   📝 Mode: dev"

log_to_file "$FRONTEND_LOG" "=== DÉMARRAGE FRONTEND REACT ROUTER ==="
log_to_file "$FRONTEND_LOG" "Répertoire: $(pwd)/frontend"
log_to_file "$FRONTEND_LOG" "Port: 5173"
log_to_file "$FRONTEND_LOG" "Mode: dev"

cd frontend

# Vérifier que les fichiers nécessaires existent
if [ ! -f "package.json" ]; then
    log_error "package.json non trouvé dans le dossier frontend !"
    log_to_file "$FRONTEND_LOG" "ERREUR: package.json non trouvé"
    kill $backend_pid 2>/dev/null
    exit 1
fi

# Vérifier et installer les dépendances si nécessaire
if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
    log_warning "Dépendances frontend manquantes, installation..."
    log_to_file "$FRONTEND_LOG" "Installation des dépendances NPM..."
    npm install >> "$FRONTEND_LOG" 2>&1
    log_to_file "$FRONTEND_LOG" "Dépendances installées"
fi

# Démarrer Vite en arrière-plan avec logs détaillés
log_to_file "$FRONTEND_LOG" "Commande: npm run dev"
npm run dev >> "$FRONTEND_LOG" 2>&1 &
frontend_pid=$!

log_to_file "$FRONTEND_LOG" "Processus Vite démarré (PID: $frontend_pid)"
log_to_file "$SYSTEM_LOG" "Frontend Vite démarré (PID: $frontend_pid)"

cd ..

log_success "Frontend Vite lancé (PID: $frontend_pid)"
log_info "📝 Logs frontend: tail -f logs/frontend.log"

# Attendre que Vite soit prêt
echo ""
wait_for_service "http://localhost:5173" "Frontend"

# Résumé final
echo ""
echo "🎉 ✅ SERVICES DÉMARRÉS AVEC SUCCÈS !"
echo "===================================="
echo ""
echo "📊 Informations des services:"
echo "   🔸 Backend Strapi:"
echo "     • PID: $backend_pid"
echo "     • Port: 1440"
echo "     • Admin: http://localhost:1440/admin"
echo "     • API: http://localhost:1440/api"
echo ""
echo "   🔸 Frontend Vite:"
echo "     • PID: $frontend_pid"
echo "     • Port: 5173"
echo "     • Interface: http://localhost:5173"
echo ""
echo "🌐 URLs de production:"
echo "   🔸 Frontend: https://blog.votre-domaine.com"
echo "   🔸 Backend: https://cms.votre-domaine.com/admin"
echo ""
echo "📝 Commandes utiles:"
echo "   🔸 Arrêter les services: ./stop-services.sh"
echo "   🔸 Voir logs backend: tail -f logs/backend.log"
echo "   🔸 Voir logs frontend: tail -f logs/frontend.log"
echo "   🔸 Vérifier les ports: lsof -i:1440 && lsof -i:5173"
echo ""
echo "💡 Les services tournent en arrière-plan."
echo "   Utilisez Ctrl+C ou ./stop-services.sh pour les arrêter."

# Sauvegarder les PIDs pour référence
echo "$backend_pid" > logs/backend.pid
echo "$frontend_pid" > logs/frontend.pid

# Logger les informations de performance initiales
log_performance "Backend-Strapi" "$backend_pid" "1440"
log_performance "Frontend-Vite" "$frontend_pid" "5173"

log_success "PIDs sauvegardés dans logs/"

# Logger le succès du démarrage
log_to_file "$SYSTEM_LOG" "=== SERVICES DÉMARRÉS AVEC SUCCÈS ==="
log_to_file "$SYSTEM_LOG" "Backend PID: $backend_pid (Port: 1440)"
log_to_file "$SYSTEM_LOG" "Frontend PID: $frontend_pid (Port: 5173)"

# Proposer d'activer le monitoring automatique
echo ""
read -p "🤔 Voulez-vous activer le monitoring automatique de Strapi ? (Y/n): " enable_monitoring

if [[ ! $enable_monitoring =~ ^[Nn]$ ]]; then
    echo ""
    log_info "🔍 Activation du monitoring automatique..."
    
    # Vérifier si le service systemd existe
    if [ -f "/etc/systemd/system/strapi-monitor.service" ]; then
        log_info "Démarrage du service de monitoring..."
        systemctl start strapi-monitor 2>/dev/null || true
        if systemctl is-active --quiet strapi-monitor; then
            log_success "✅ Monitoring automatique activé !"
        else
            log_warning "⚠️ Problème avec le service systemd, démarrage manuel..."
            nohup ./monitor-strapi.sh monitor > logs/monitor.log 2>&1 &
            monitor_pid=$!
            echo "$monitor_pid" > logs/monitor.pid
            log_success "✅ Monitoring manuel démarré en arrière-plan (PID: $monitor_pid)"
        fi
    else
        log_info "Service systemd non installé, démarrage manuel..."
        nohup ./monitor-strapi.sh monitor > logs/monitor.log 2>&1 &
        monitor_pid=$!
        echo "$monitor_pid" > logs/monitor.pid
        log_success "✅ Monitoring manuel démarré en arrière-plan (PID: $monitor_pid)"
        echo ""
        echo "💡 Pour installer le monitoring automatique permanent:"
        echo "   sudo ./install-monitor.sh"
    fi
    
    echo ""
    echo "🔍 Commandes de monitoring:"
    echo "   🔸 Vérification santé: ./monitor-strapi.sh check"
    echo "   🔸 Statistiques: ./monitor-strapi.sh stats"
    echo "   🔸 Logs monitoring: ./monitor-strapi.sh logs"
    echo "   🔸 Redémarrage forcé: ./monitor-strapi.sh restart"
fi
