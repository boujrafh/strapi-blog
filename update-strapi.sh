#!/bin/bash

# 🚀 Script de mise à jour Strapi vers la dernière version
echo "🚀 Mise à jour Strapi vers la dernière version"
echo "============================================="

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

# Vérifier qu'on est dans le bon dossier ou naviguer vers backend
if [ -f "package.json" ] && grep -q "@strapi/strapi" package.json; then
    # Nous sommes dans le dossier backend
    BACKEND_DIR="."
elif [ -f "backend/package.json" ] && grep -q "@strapi/strapi" backend/package.json; then
    # Nous sommes dans le dossier parent
    BACKEND_DIR="backend"
    cd backend
elif [ -f "../package.json" ] && grep -q "@strapi/strapi" ../package.json; then
    # Nous sommes dans un sous-dossier
    BACKEND_DIR=".."
    cd ..
else
    log_error "Impossible de trouver le dossier Strapi"
    log_error "Assurez-vous d'être dans le dossier contenant package.json avec @strapi/strapi"
    exit 1
fi

log_info "📁 Dossier Strapi détecté: $(pwd)"

# Fonction pour créer une sauvegarde
create_backup() {
    local backup_dir="/home/myblog/backups/strapi-$(date +%Y%m%d-%H%M%S)"
    
    log_info "🗂️ Création d'une sauvegarde..."
    mkdir -p "$backup_dir"
    
    # Sauvegarder les fichiers critiques
    cp package.json "$backup_dir/"
    cp package-lock.json "$backup_dir/" 2>/dev/null || true
    cp -r config "$backup_dir/" 2>/dev/null || true
    cp -r src "$backup_dir/" 2>/dev/null || true
    cp -r database "$backup_dir/" 2>/dev/null || true
    cp .env "$backup_dir/" 2>/dev/null || true
    
    log_success "Sauvegarde créée: $backup_dir"
    echo "$backup_dir" > /tmp/strapi_backup_path
}

# Fonction pour afficher les versions
show_versions() {
    echo ""
    log_info "📊 Versions Strapi:"
    
    local current_version=$(grep '"@strapi/strapi"' package.json | sed 's/.*": *"//;s/".*//')
    local latest_version=$(npm show @strapi/strapi version 2>/dev/null | tail -1)
    
    echo "   🔹 Version actuelle: $current_version"
    echo "   🔹 Dernière version: $latest_version"
    
    if [ "$current_version" = "$latest_version" ]; then
        log_success "Strapi est déjà à jour !"
        return 0
    else
        log_warning "Mise à jour disponible: $current_version → $latest_version"
        return 1
    fi
}

# Fonction pour résoudre les problèmes useContext
fix_usecontext_issues() {
    echo ""
    log_info "🔧 Résolution des problèmes useContext..."
    
    # 1. Nettoyer le cache Strapi
    log_info "1️⃣ Nettoyage du cache Strapi..."
    rm -rf .tmp/
    rm -rf .cache/
    rm -rf .strapi/
    rm -rf dist/
    log_success "Cache nettoyé"
    
    # 2. Vérifier la configuration Vite
    local vite_config="src/admin/vite.config.ts"
    if [ -f "$vite_config" ]; then
        log_info "2️⃣ Vérification configuration Vite..."
        
        # Vérifier si allowedHosts est configuré
        if grep -q "allowedHosts" "$vite_config"; then
            log_success "Configuration allowedHosts présente"
        else
            log_warning "Configuration allowedHosts manquante"
            log_info "Ajout de la configuration allowedHosts..."
            
            # Créer une configuration Vite mise à jour
            cat > "$vite_config" << 'EOF'
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    fs: {
      strict: false,
    },
    host: true,
    port: 1337,
    allowedHosts: [
      'cms.bh-systems.be',
      'localhost',
      '127.0.0.1',
      '0.0.0.0'
    ]
  },
  build: {
    sourcemap: false,
    rollupOptions: {
      external: ['fsevents']
    }
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom']
  }
});
EOF
            log_success "Configuration Vite mise à jour"
        fi
    else
        log_warning "Fichier vite.config.ts non trouvé, création..."
        mkdir -p src/admin
        cat > "$vite_config" << 'EOF'
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    fs: {
      strict: false,
    },
    host: true,
    port: 1337,
    allowedHosts: [
      'cms.bh-systems.be',
      'localhost',
      '127.0.0.1',
      '0.0.0.0'
    ]
  },
  build: {
    sourcemap: false,
    rollupOptions: {
      external: ['fsevents']
    }
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom']
  }
});
EOF
        log_success "Configuration Vite créée"
    fi
    
    # 3. Mettre à jour les dépendances React
    log_info "3️⃣ Mise à jour des dépendances React..."
    npm update react react-dom react-router-dom
    log_success "Dépendances React mises à jour"
}

# Fonction pour mettre à jour Strapi
update_strapi() {
    echo ""
    log_info "🚀 Mise à jour de Strapi..."
    
    # Arrêter Strapi s'il tourne
    log_info "Arrêt de Strapi..."
    pkill -f "strapi" || true
    sleep 2
    
    # Utiliser l'outil officiel de mise à jour Strapi
    log_info "Exécution de la mise à jour Strapi..."
    if npx @strapi/upgrade latest; then
        log_success "Mise à jour Strapi terminée"
    else
        log_warning "Problème avec l'outil de mise à jour, mise à jour manuelle..."
        
        # Mise à jour manuelle
        npm update @strapi/strapi @strapi/plugin-users-permissions @strapi/plugin-cloud
        
        # Réinstaller les dépendances
        log_info "Réinstallation des dépendances..."
        rm -rf node_modules
        npm install
        log_success "Dépendances réinstallées"
    fi
}

# Fonction pour reconstruire Strapi
rebuild_strapi() {
    echo ""
    log_info "🔨 Reconstruction de Strapi..."
    
    # Build de l'admin
    log_info "Construction de l'interface admin..."
    npm run build
    
    if [ $? -eq 0 ]; then
        log_success "Construction réussie"
    else
        log_error "Erreur lors de la construction"
        return 1
    fi
}

# Fonction pour tester après mise à jour
test_after_update() {
    echo ""
    log_info "🧪 Test après mise à jour..."
    
    # Démarrer Strapi en arrière-plan
    log_info "Démarrage de Strapi pour test..."
    npm run develop &
    local strapi_pid=$!
    
    # Attendre le démarrage
    sleep 15
    
    # Tester la connectivité
    local test_count=0
    local max_tests=6
    
    while [ $test_count -lt $max_tests ]; do
        if curl -s http://localhost:1440/admin >/dev/null 2>&1; then
            log_success "Strapi répond correctement"
            
            # Tester l'API
            if curl -s http://localhost:1440/api/posts >/dev/null 2>&1; then
                log_success "API fonctionne"
            else
                log_warning "API ne répond pas (normal si pas de token)"
            fi
            
            # Arrêter le test
            kill $strapi_pid 2>/dev/null
            return 0
        fi
        
        test_count=$((test_count + 1))
        log_info "Tentative $test_count/$max_tests..."
        sleep 10
    done
    
    log_error "Strapi ne répond pas après mise à jour"
    kill $strapi_pid 2>/dev/null
    return 1
}

# Menu principal
show_menu() {
    echo ""
    echo "🚀 Mise à jour Strapi - Menu"
    echo "============================"
    echo ""
    echo "1️⃣  📊 Afficher les versions"
    echo "2️⃣  🗂️ Créer une sauvegarde"
    echo "3️⃣  🔧 Résoudre problèmes useContext"
    echo "4️⃣  🚀 Mettre à jour Strapi"
    echo "5️⃣  🔨 Reconstruire Strapi"
    echo "6️⃣  🧪 Tester Strapi"
    echo "7️⃣  🎯 Mise à jour complète (tout en un)"
    echo "8️⃣  Quitter"
    echo ""
    read -p "Choisissez une option (1-8): " choice
    
    case $choice in
        1) show_versions ;;
        2) create_backup ;;
        3) fix_usecontext_issues ;;
        4) update_strapi ;;
        5) rebuild_strapi ;;
        6) test_after_update ;;
        7) full_update ;;
        8) exit 0 ;;
        *) log_error "Option invalide" ;;
    esac
}

# Fonction de mise à jour complète
full_update() {
    echo ""
    log_info "🎯 Mise à jour complète de Strapi..."
    echo "===================================="
    
    # Étapes de la mise à jour complète
    create_backup || { log_error "Échec de la sauvegarde"; return 1; }
    fix_usecontext_issues || { log_error "Échec correction useContext"; return 1; }
    update_strapi || { log_error "Échec mise à jour Strapi"; return 1; }
    rebuild_strapi || { log_error "Échec reconstruction"; return 1; }
    test_after_update || { log_error "Échec du test"; return 1; }
    
    echo ""
    log_success "🎉 Mise à jour complète terminée !"
    echo ""
    echo "📋 Résumé:"
    echo "   ✅ Sauvegarde créée"
    echo "   ✅ Problèmes useContext corrigés"
    echo "   ✅ Strapi mis à jour"
    echo "   ✅ Interface admin reconstruite"
    echo "   ✅ Tests de fonctionnement OK"
    echo ""
    echo "💡 Actions recommandées:"
    echo "   🔹 Redémarrer avec: npm run develop"
    echo "   🔹 Tester l'admin: https://cms.bh-systems.be/admin"
    echo "   🔹 Vérifier les logs: tail -f logs/backend.log"
}

# Point d'entrée principal
case "${1:-menu}" in
    "menu") 
        while true; do
            show_menu
            echo ""
            read -p "Appuyez sur Entrée pour continuer..."
        done
        ;;
    "versions") show_versions ;;
    "backup") create_backup ;;
    "fix-usecontext") fix_usecontext_issues ;;
    "update") update_strapi ;;
    "rebuild") rebuild_strapi ;;
    "test") test_after_update ;;
    "full") full_update ;;
    *)
        echo "Usage: $0 {menu|versions|backup|fix-usecontext|update|rebuild|test|full}"
        echo ""
        echo "Options:"
        echo "  menu          - Menu interactif (défaut)"
        echo "  versions      - Afficher les versions"
        echo "  backup        - Créer une sauvegarde"
        echo "  fix-usecontext- Résoudre problèmes useContext"
        echo "  update        - Mettre à jour Strapi"
        echo "  rebuild       - Reconstruire Strapi"
        echo "  test          - Tester Strapi"
        echo "  full          - Mise à jour complète"
        exit 1
        ;;
esac
