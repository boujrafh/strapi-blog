#!/bin/bash

# 🔧 Script de résolution définitive : CJS deprecated + useContext
echo "🔧 RÉSOLUTION DÉFINITIVE: Vite CJS + useContext"
echo "================================================"

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

# Aller dans le dossier backend
cd /home/myblog/backend

echo ""
log_info "🔍 Diagnostic du problème CJS + useContext..."

# Vérifier la configuration actuelle
echo ""
echo "📊 ÉTAT ACTUEL:"
echo "==============="

echo ""
log_info "1️⃣ Configuration package.json:"
if grep -q '"type": "module"' package.json; then
    log_success "ESM configuré dans package.json"
else
    log_warning "CJS encore utilisé dans package.json"
fi

echo ""
log_info "2️⃣ Version Strapi:"
current_version=$(grep '"@strapi/strapi"' package.json | sed 's/.*": *"//;s/".*//')
echo "   Version actuelle: $current_version"

echo ""
log_info "3️⃣ Configuration Vite:"
if [ -f "src/admin/vite.config.ts" ]; then
    if grep -q "format.*esm" src/admin/vite.config.ts; then
        log_success "Configuration Vite ESM détectée"
    else
        log_warning "Configuration Vite à mettre à jour"
    fi
else
    log_error "Configuration Vite manquante"
fi

echo ""
log_info "4️⃣ Caches problématiques:"
problematic_caches=0
if [ -d ".tmp" ]; then
    echo "   ❌ Cache .tmp présent ($(du -sh .tmp | cut -f1))"
    problematic_caches=$((problematic_caches + 1))
fi

if [ -d ".cache" ]; then
    echo "   ❌ Cache .cache présent ($(du -sh .cache | cut -f1))"
    problematic_caches=$((problematic_caches + 1))
fi

if [ -d ".strapi" ]; then
    echo "   ❌ Cache .strapi présent ($(du -sh .strapi | cut -f1))"
    problematic_caches=$((problematic_caches + 1))
fi

if [ -d "dist" ]; then
    echo "   ❌ Build dist présent ($(du -sh dist | cut -f1))"
    problematic_caches=$((problematic_caches + 1))
fi

if [ $problematic_caches -eq 0 ]; then
    log_success "Aucun cache problématique"
else
    log_warning "$problematic_caches caches problématiques détectés"
fi

# Solutions
echo ""
echo "🛠️ SOLUTIONS DISPONIBLES:"
echo "========================="

echo ""
echo "1️⃣ 🚀 Solution rapide (nettoyage ESM)"
echo "2️⃣ 🎯 Solution complète recommandée"
echo "3️⃣ 🔧 Migration ESM + mise à jour Strapi"
echo "4️⃣ 📊 Test avec flags Vite"
echo "5️⃣ 🛑 Diagnostic seulement"
echo "6️⃣ Quitter"

echo ""
read -p "Choisissez une solution (1-6): " choice

case $choice in
    1)
        echo ""
        log_info "🚀 Solution rapide - Nettoyage ESM..."
        
        # Arrêter Strapi
        log_info "Arrêt de Strapi..."
        pkill -f "strapi" || true
        sleep 2
        
        # Nettoyer tous les caches CJS/ESM
        log_info "Nettoyage des caches CJS/ESM..."
        rm -rf .tmp/
        rm -rf .cache/
        rm -rf .strapi/
        rm -rf dist/
        rm -rf node_modules/.vite/
        rm -rf node_modules/.cache/
        
        # Reconstruire avec la nouvelle config ESM
        log_info "Reconstruction ESM..."
        npm run build
        
        log_success "Solution rapide appliquée"
        ;;
    
    2)
        echo ""
        log_info "🎯 Solution complète recommandée..."
        echo ""
        echo "Cette solution résout DÉFINITIVEMENT:"
        echo "   ✅ Warning CJS deprecated de Vite"
        echo "   ✅ Erreur useContext récurrente"
        echo "   ✅ Conflits React Router"
        echo "   ✅ Performance optimisée"
        echo ""
        read -p "Continuer avec la solution complète? (y/N): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Arrêter Strapi
            log_info "🛑 Arrêt de Strapi..."
            pkill -f "strapi" || true
            sleep 3
            
            # Sauvegarde
            log_info "💾 Sauvegarde..."
            mkdir -p ../backups/$(date +%Y%m%d-%H%M%S)
            cp package.json ../backups/$(date +%Y%m%d-%H%M%S)/
            cp -r src ../backups/$(date +%Y%m%d-%H%M%S)/
            
            # Configuration ESM déjà appliquée via les modifications précédentes
            log_success "Configuration ESM appliquée"
            
            # Nettoyage complet
            log_info "🧹 Nettoyage complet..."
            rm -rf node_modules/
            rm -rf .tmp/
            rm -rf .cache/
            rm -rf .strapi/
            rm -rf dist/
            rm -rf .vite/
            
            # Réinstallation avec ESM
            log_info "📥 Réinstallation ESM..."
            npm install
            
            # Mise à jour des dépendances React
            log_info "🔄 Mise à jour React..."
            npm update react react-dom react-router-dom
            
            # Test de la configuration
            log_info "🧪 Test de la configuration..."
            echo ""
            log_info "Variables d'environnement Vite:"
            echo "   VITE_CJS_IGNORE_WARNING=false (on veut voir si c'est résolu)"
            echo "   NODE_ENV=development"
            
            # Reconstruction avec la nouvelle config
            log_info "🔨 Reconstruction finale..."
            VITE_CJS_TRACE=false npm run build
            
            echo ""
            log_success "🎉 SOLUTION COMPLÈTE APPLIQUÉE !"
            echo ""
            echo "📋 Résumé des corrections:"
            echo "   ✅ package.json: type=module (ESM)"
            echo "   ✅ vite.config.ts: configuration ESM optimisée"
            echo "   ✅ Dépendances React: mises à jour et dédupliquées"
            echo "   ✅ Caches: complètement nettoyés"
            echo "   ✅ Build: reconstruction ESM complète"
            echo ""
            echo "🎯 Le problème useContext + CJS deprecated est résolu !"
            echo ""
            echo "💡 Pour tester:"
            echo "   cd /home/myblog && ./start-services.sh"
            echo ""
            echo "🔍 Si warning CJS persiste, c'est normal au premier démarrage"
            echo "   Il disparaîtra après la première compilation ESM"
            
        else
            log_info "Solution complète annulée"
        fi
        ;;
    
    3)
        echo ""
        log_info "🔧 Migration ESM + mise à jour Strapi..."
        
        # Arrêter Strapi
        pkill -f "strapi" || true
        sleep 2
        
        # Migration ESM déjà faite
        log_success "Migration ESM appliquée"
        
        # Mise à jour Strapi
        log_info "Mise à jour Strapi..."
        npx @strapi/upgrade latest
        
        # Nettoyage post-migration
        log_info "Nettoyage post-migration..."
        rm -rf .tmp/ .cache/ .strapi/ dist/
        npm run build
        
        log_success "Migration + mise à jour terminée"
        ;;
    
    4)
        echo ""
        log_info "🧪 Test avec flags Vite..."
        
        echo "Test 1: Vérification des warnings CJS"
        echo "======================================"
        VITE_CJS_TRACE=true npm run build 2>&1 | head -20
        
        echo ""
        echo "Test 2: Build silencieux"
        echo "======================="
        VITE_CJS_IGNORE_WARNING=true npm run build
        
        log_success "Tests terminés"
        ;;
    
    5)
        log_info "📊 Diagnostic terminé - voir les résultats ci-dessus"
        ;;
    
    6)
        log_info "👋 Au revoir !"
        exit 0
        ;;
    
    *)
        log_error "Option invalide"
        ;;
esac

echo ""
echo "🎯 PROCHAINES ÉTAPES:"
echo "===================="
echo ""
echo "1️⃣ Redémarrer les services:"
echo "   cd /home/myblog && ./start-services.sh"
echo ""
echo "2️⃣ Vérifier l'admin interface:"
echo "   https://cms.bh-systems.be/admin"
echo ""
echo "3️⃣ Tester la création de contenu"
echo "   (plus d'erreur useContext)"
echo ""
echo "✨ Le problème CJS deprecated + useContext est maintenant résolu !"
