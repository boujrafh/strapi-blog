#!/bin/bash

# 🔄 Script pour redémarrer complètement les services
# Arrête tout puis redémarre proprement

echo "🔄 Redémarrage des services blog"
echo "==============================="

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Vérifier que les scripts existent
if [ ! -f "stop-services.sh" ] || [ ! -f "start-services.sh" ]; then
    echo "❌ Scripts stop-services.sh ou start-services.sh manquants !"
    exit 1
fi

echo ""
log_info "🛑 Phase 1: Arrêt des services..."
./stop-services.sh

echo ""
echo "⏳ Attente de 3 secondes pour stabilisation..."
sleep 3

echo ""
log_info "🚀 Phase 2: Démarrage des services..."
./start-services.sh

echo ""
log_success "🔄 Redémarrage terminé !"
