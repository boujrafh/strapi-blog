#!/bin/bash

# 🚀 Script pour démarrer le backend et frontend
# Lance Strapi puis le frontend Vite

echo "🚀 Démarrage des applications blog"
echo "=================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
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

cd backend

# Vérifier que les fichiers nécessaires existent
if [ ! -f "package.json" ]; then
    log_error "package.json non trouvé dans le dossier backend !"
    exit 1
fi

# Démarrer Strapi en arrière-plan
npm run develop > ../logs/backend.log 2>&1 &
backend_pid=$!

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

cd frontend

# Vérifier que les fichiers nécessaires existent
if [ ! -f "package.json" ]; then
    log_error "package.json non trouvé dans le dossier frontend !"
    kill $backend_pid 2>/dev/null
    exit 1
fi

# Démarrer Vite en arrière-plan
npm run dev > ../logs/frontend.log 2>&1 &
frontend_pid=$!

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

log_success "PIDs sauvegardés dans logs/"
