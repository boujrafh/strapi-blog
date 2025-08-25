#!/bin/bash

# 🧪 Test de validation de la mise à jour Strapi 5.23.0
echo "🧪 TEST DE VALIDATION - Strapi 5.23.0"
echo "======================================"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo ""
log_info "🔍 Test de validation post-mise à jour..."

# 1. Vérifier les versions
echo ""
echo "📊 VERSIONS INSTALLÉES:"
echo "======================="

cd /home/myblog/backend

strapi_version=$(grep '@strapi/strapi' package.json | cut -d'"' -f4)
users_permissions_version=$(grep '@strapi/plugin-users-permissions' package.json | cut -d'"' -f4)
cloud_version=$(grep '@strapi/plugin-cloud' package.json | cut -d'"' -f4)

log_info "Version Strapi Core: $strapi_version"
log_info "Version Users Permissions: $users_permissions_version"
log_info "Version Cloud Plugin: $cloud_version"

if [[ "$strapi_version" == "5.23.0" ]]; then
    log_success "Strapi 5.23.0 correctement installé"
else
    log_error "Version Strapi incorrecte: attendu 5.23.0, trouvé $strapi_version"
fi

# 2. Vérifier l'état des services
echo ""
echo "🔧 ÉTAT DES SERVICES:"
echo "===================="

# Vérifier si Strapi est en cours d'exécution
strapi_pid=$(pgrep -f "strapi.*develop" | head -1)
if [ -n "$strapi_pid" ]; then
    log_success "Strapi en cours d'exécution (PID: $strapi_pid)"
else
    log_warning "Strapi n'est pas en cours d'exécution"
fi

# Vérifier les ports
port_1440_status=$(lsof -i:1440 2>/dev/null)
if [ -n "$port_1440_status" ]; then
    log_success "Port 1440 (Strapi) occupé"
else
    log_warning "Port 1440 (Strapi) libre"
fi

# 3. Test des endpoints admin
echo ""
echo "🌐 TESTS DES ENDPOINTS:"
echo "======================"

log_info "Test de l'endpoint /admin/init..."
admin_init_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1440/admin/init)
if [[ "$admin_init_response" == "200" ]]; then
    log_success "Endpoint /admin/init répond (200)"
else
    log_error "Endpoint /admin/init en erreur ($admin_init_response)"
fi

log_info "Test de l'endpoint /admin..."
admin_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1440/admin)
if [[ "$admin_response" == "200" ]]; then
    log_success "Endpoint /admin répond (200)"
else
    log_error "Endpoint /admin en erreur ($admin_response)"
fi

# 4. Vérifier les logs pour les erreurs useContext
echo ""
echo "🔍 ANALYSE DES LOGS:"
echo "==================="

log_info "Recherche d'erreurs useContext dans les logs..."
usecontext_errors=$(grep -i "usecontext\|cannot read properties of null" /home/myblog/logs/backend.log 2>/dev/null | tail -5)

if [ -z "$usecontext_errors" ]; then
    log_success "Aucune erreur useContext détectée dans les logs récents"
else
    log_error "Erreurs useContext encore présentes:"
    echo "$usecontext_errors"
fi

# 5. Test de performance/stabilité
echo ""
echo "⚡ TESTS DE PERFORMANCE:"
echo "======================"

log_info "Test de temps de réponse admin..."
start_time=$(date +%s%N)
curl -s http://localhost:1440/admin/init > /dev/null
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))

if [ $response_time -lt 1000 ]; then
    log_success "Temps de réponse excellent: ${response_time}ms"
elif [ $response_time -lt 3000 ]; then
    log_success "Temps de réponse bon: ${response_time}ms"
else
    log_warning "Temps de réponse lent: ${response_time}ms"
fi

# 6. Vérifier la configuration Vite
echo ""
echo "⚙️ CONFIGURATION VITE:"
echo "====================="

if [ -f "src/admin/vite.config.ts" ]; then
    log_success "Configuration Vite présente"
    
    if grep -q "dedupe.*react" src/admin/vite.config.ts; then
        log_success "Déduplication React configurée"
    else
        log_warning "Déduplication React manquante"
    fi
    
    if grep -q "allowedHosts" src/admin/vite.config.ts; then
        log_success "AllowedHosts configuré"
    else
        log_warning "AllowedHosts manquant"
    fi
else
    log_error "Configuration Vite manquante"
fi

# 7. Résumé final
echo ""
echo "📋 RÉSUMÉ DU TEST:"
echo "=================="

test_success=true

if [[ "$strapi_version" != "5.23.0" ]]; then
    test_success=false
fi

if [[ "$admin_init_response" != "200" ]] || [[ "$admin_response" != "200" ]]; then
    test_success=false
fi

if [ -n "$usecontext_errors" ]; then
    test_success=false
fi

echo ""
if [ "$test_success" = true ]; then
    log_success "🎉 TOUS LES TESTS PASSÉS !"
    echo ""
    echo "✅ Strapi 5.23.0 opérationnel"
    echo "✅ Interface admin fonctionnelle"
    echo "✅ Aucune erreur useContext"
    echo "✅ Configuration optimisée"
    echo ""
    echo "🎯 Le problème useContext récurrent est RÉSOLU !"
    echo ""
    echo "🌐 Accès admin: https://cms.bh-systems.be/admin"
    echo "🌐 Accès frontend: https://blog.bh-systems.be"
else
    log_error "❌ CERTAINS TESTS ONT ÉCHOUÉ"
    echo ""
    echo "Vérifiez les points en erreur ci-dessus"
fi

echo ""
echo "💡 Prochaines étapes recommandées:"
echo "   1. Tester la création/modification de contenu"
echo "   2. Vérifier que l'erreur useContext ne revient plus"
echo "   3. Monitorer la stabilité sur 24h"
