#!/bin/bash

# 📊 Script pour vérifier le statut des services
# Affiche l'état du backend et frontend

echo "📊 Statut des services blog"
echo "==========================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction pour vérifier un service
check_service() {
    local url=$1
    local name=$2
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        log_success "$name : ACTIF"
        return 0
    else
        log_error "$name : INACTIF"
        return 1
    fi
}

# Fonction pour vérifier un port
check_port() {
    local port=$1
    local service_name=$2
    
    local process_info=$(lsof -i:$port 2>/dev/null)
    
    if [ -n "$process_info" ]; then
        log_success "Port $port ($service_name) : OCCUPÉ"
        echo "$process_info" | tail -n +2 | while read line; do
            echo "    $line"
        done
        return 0
    else
        log_warning "Port $port ($service_name) : LIBRE"
        return 1
    fi
}

echo ""
log_info "🔍 Vérification des ports..."

# Vérifier les ports
echo ""
echo "📊 État des ports:"
check_port 1440 "Strapi"
echo ""
check_port 5173 "Frontend"

echo ""
echo "📊 Processus liés au projet:"
project_processes=$(ps aux | grep -E "(npm|node|strapi)" | grep -v grep | grep -E "(myblog|1440|5173|develop|dev)")
if [ -n "$project_processes" ]; then
    echo "$project_processes"
else
    log_warning "Aucun processus lié au projet détecté"
fi

echo ""
log_info "🌐 Test de connectivité des services..."

# Tester les services locaux
echo ""
echo "📊 Services locaux:"
check_service "http://localhost:1440" "Backend Strapi (localhost:1440)"
check_service "http://localhost:5173" "Frontend Vite (localhost:5173)"

# Tester les services de production (si configurés)
echo ""
echo "📊 Services de production:"
if curl -s -f "https://cms.votre-domaine.com" > /dev/null 2>&1; then
    log_success "Backend production : ACCESSIBLE"
else
    log_warning "Backend production : NON ACCESSIBLE ou non configuré"
fi

if curl -s -f "https://blog.votre-domaine.com" > /dev/null 2>&1; then
    log_success "Frontend production : ACCESSIBLE"
else
    log_warning "Frontend production : NON ACCESSIBLE ou non configuré"
fi

# Vérifier les logs si ils existent
echo ""
echo "📝 Logs disponibles:"
if [ -f "logs/backend.log" ]; then
    backend_log_size=$(wc -l < logs/backend.log)
    log_info "Backend logs : $backend_log_size lignes (logs/backend.log)"
else
    log_warning "Pas de logs backend trouvés"
fi

if [ -f "logs/frontend.log" ]; then
    frontend_log_size=$(wc -l < logs/frontend.log)
    log_info "Frontend logs : $frontend_log_size lignes (logs/frontend.log)"
else
    log_warning "Pas de logs frontend trouvés"
fi

# Vérifier les PIDs sauvegardés
echo ""
echo "📍 PIDs sauvegardés:"
if [ -f "logs/backend.pid" ]; then
    backend_pid=$(cat logs/backend.pid)
    if ps -p $backend_pid > /dev/null 2>&1; then
        log_success "Backend PID $backend_pid : ACTIF"
    else
        log_error "Backend PID $backend_pid : INACTIF (processus terminé)"
    fi
else
    log_warning "Pas de PID backend sauvegardé"
fi

if [ -f "logs/frontend.pid" ]; then
    frontend_pid=$(cat logs/frontend.pid)
    if ps -p $frontend_pid > /dev/null 2>&1; then
        log_success "Frontend PID $frontend_pid : ACTIF"
    else
        log_error "Frontend PID $frontend_pid : INACTIF (processus terminé)"
    fi
else
    log_warning "Pas de PID frontend sauvegardé"
fi

echo ""
echo "💡 Commandes utiles:"
echo "   🔸 Démarrer: ./start-services.sh"
echo "   🔸 Arrêter: ./stop-services.sh"
echo "   🔸 Redémarrer: ./restart-services.sh"
echo "   🔸 Logs backend: tail -f logs/backend.log"
echo "   🔸 Logs frontend: tail -f logs/frontend.log"
