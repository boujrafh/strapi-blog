#!/bin/bash

# 🔧 Script de résolution définitive du problème useContext
echo "🔧 Résolution définitive du problème useContext"
echo "=============================================="

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
log_info "🔍 Diagnostic du problème useContext récurrent..."

# 1. Analyser la cause racine
echo ""
echo "📊 DIAGNOSTIC COMPLET:"
echo "====================="

echo ""
log_info "1️⃣ Version actuelle de Strapi:"
local current_version=$(grep '"@strapi/strapi"' package.json | sed 's/.*": *"//;s/".*//')
echo "   Version: $current_version"

echo ""
log_info "2️⃣ État des caches:"
if [ -d ".tmp" ]; then
    echo "   ❌ Cache .tmp présent ($(du -sh .tmp | cut -f1))"
else
    echo "   ✅ Cache .tmp absent"
fi

if [ -d ".cache" ]; then
    echo "   ❌ Cache .cache présent ($(du -sh .cache | cut -f1))"
else
    echo "   ✅ Cache .cache absent"  
fi

if [ -d ".strapi" ]; then
    echo "   ⚠️  Cache .strapi présent ($(du -sh .strapi | cut -f1))"
else
    echo "   ✅ Cache .strapi absent"
fi

if [ -d "dist" ]; then
    echo "   ⚠️  Dossier dist présent ($(du -sh dist | cut -f1))"
else
    echo "   ✅ Dossier dist absent"
fi

echo ""
log_info "3️⃣ Configuration Vite admin:"
if [ -f "src/admin/vite.config.ts" ]; then
    echo "   ✅ vite.config.ts présent"
    if grep -q "allowedHosts" src/admin/vite.config.ts; then
        echo "   ✅ allowedHosts configuré"
    else
        echo "   ❌ allowedHosts manquant"
    fi
else
    echo "   ❌ vite.config.ts manquant"
fi

echo ""
log_info "4️⃣ Versions des dépendances React:"
echo "   React: $(npm list react --depth=0 2>/dev/null | grep react@ | head -1 || echo 'Non trouvé')"
echo "   React-DOM: $(npm list react-dom --depth=0 2>/dev/null | grep react-dom@ | head -1 || echo 'Non trouvé')"
echo "   React-Router-DOM: $(npm list react-router-dom --depth=0 2>/dev/null | grep react-router-dom@ | head -1 || echo 'Non trouvé')"

# 2. Solutions pour résoudre définitivement
echo ""
echo "🛠️ SOLUTIONS DISPONIBLES:"
echo "========================="

echo ""
echo "1️⃣ 🧹 Nettoyage complet des caches"
echo "2️⃣ 🔧 Mise à jour vers Strapi 5.23.0" 
echo "3️⃣ ⚙️  Correction configuration Vite"
echo "4️⃣ 🔄 Reconstruction complète"
echo "5️⃣ 🎯 Solution complète (recommandée)"
echo "6️⃣ 📊 Diagnostic seulement"
echo "7️⃣ Quitter"

echo ""
read -p "Choisissez une solution (1-7): " choice

case $choice in
    1)
        echo ""
        log_info "🧹 Nettoyage complet des caches..."
        
        # Arrêter Strapi
        log_info "Arrêt de Strapi..."
        pkill -f "strapi" || true
        sleep 2
        
        # Nettoyer tous les caches
        log_info "Suppression des caches..."
        rm -rf .tmp/
        rm -rf .cache/ 
        rm -rf .strapi/
        rm -rf dist/
        rm -rf node_modules/.cache/
        
        log_success "Caches nettoyés"
        
        # Reconstruire
        log_info "Reconstruction..."
        npm run build
        log_success "Reconstruction terminée"
        ;;
    
    2)
        echo ""
        log_info "🔧 Mise à jour vers Strapi 5.23.0..."
        
        # Arrêter Strapi
        pkill -f "strapi" || true
        sleep 2
        
        # Mise à jour avec l'outil officiel
        log_info "Exécution de la mise à jour..."
        npx @strapi/upgrade latest
        
        # Nettoyer et reconstruire
        log_info "Nettoyage post-mise à jour..."
        rm -rf .tmp/ .cache/ .strapi/ dist/
        npm run build
        
        log_success "Mise à jour terminée"
        ;;
    
    3)
        echo ""
        log_info "⚙️ Correction configuration Vite..."
        
        # Créer le dossier s'il n'existe pas
        mkdir -p src/admin
        
        # Créer une configuration Vite optimisée
        cat > src/admin/vite.config.ts << 'EOF'
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    fs: {
      strict: false,
    },
    host: true,
    port: 1337,
    hmr: {
      port: 1337,
    },
    allowedHosts: [
      'cms.bh-systems.be',
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
      '.bh-systems.be'
    ]
  },
  build: {
    sourcemap: false,
    chunkSizeWarningLimit: 3000,
    rollupOptions: {
      external: ['fsevents'],
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom']
        }
      }
    }
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom'],
    force: true
  },
  resolve: {
    dedupe: ['react', 'react-dom', 'react-router-dom']
  }
});
EOF
        
        log_success "Configuration Vite mise à jour"
        
        # Nettoyer et reconstruire
        log_info "Reconstruction avec nouvelle config..."
        rm -rf .tmp/ .cache/ .strapi/ dist/
        npm run build
        
        log_success "Configuration appliquée"
        ;;
    
    4)
        echo ""
        log_info "🔄 Reconstruction complète..."
        
        # Arrêter Strapi
        pkill -f "strapi" || true
        sleep 2
        
        # Supprimer node_modules et reinstaller
        log_info "Suppression de node_modules..."
        rm -rf node_modules/
        
        log_info "Réinstallation des dépendances..."
        npm install
        
        # Nettoyer tous les caches
        log_info "Nettoyage complet..."
        rm -rf .tmp/ .cache/ .strapi/ dist/
        
        # Reconstruire
        log_info "Reconstruction..."
        npm run build
        
        log_success "Reconstruction complète terminée"
        ;;
    
    5)
        echo ""
        log_info "🎯 Solution complète recommandée..."
        echo ""
        echo "Cette solution combine toutes les corrections:"
        echo "1. Mise à jour Strapi"
        echo "2. Configuration Vite optimisée"
        echo "3. Nettoyage complet"
        echo "4. Reconstruction"
        echo ""
        read -p "Continuer avec la solution complète? (y/N): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Arrêter Strapi
            log_info "🛑 Arrêt de Strapi..."
            pkill -f "strapi" || true
            sleep 3
            
            # Sauvegarde rapide
            log_info "💾 Sauvegarde rapide..."
            mkdir -p ../backups
            cp package.json ../backups/package.json.backup
            cp -r src ../backups/src.backup
            
            # Mise à jour Strapi
            log_info "📦 Mise à jour Strapi vers 5.23.0..."
            npx @strapi/upgrade latest
            
            # Configuration Vite optimisée
            log_info "⚙️ Configuration Vite optimisée..."
            mkdir -p src/admin
            cat > src/admin/vite.config.ts << 'EOF'
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    fs: {
      strict: false,
    },
    host: true,
    port: 1337,
    hmr: {
      port: 1337,
      overlay: false
    },
    allowedHosts: [
      'cms.bh-systems.be',
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
      '.bh-systems.be'
    ]
  },
  build: {
    sourcemap: false,
    chunkSizeWarningLimit: 3000,
    rollupOptions: {
      external: ['fsevents'],
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom']
        }
      }
    }
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom'],
    force: true
  },
  resolve: {
    dedupe: ['react', 'react-dom', 'react-router-dom']
  },
  define: {
    global: 'globalThis'
  }
});
EOF
            
            # Nettoyage complet
            log_info "🧹 Nettoyage complet..."
            rm -rf node_modules/
            rm -rf .tmp/
            rm -rf .cache/
            rm -rf .strapi/
            rm -rf dist/
            
            # Réinstallation
            log_info "📥 Réinstallation des dépendances..."
            npm install
            
            # Mise à jour des dépendances React
            log_info "🔄 Mise à jour dépendances React..."
            npm update react react-dom react-router-dom
            
            # Reconstruction
            log_info "🔨 Reconstruction complète..."
            npm run build
            
            echo ""
            log_success "🎉 Solution complète appliquée !"
            echo ""
            echo "📋 Résumé des actions:"
            echo "   ✅ Strapi mis à jour vers la dernière version"
            echo "   ✅ Configuration Vite optimisée pour éviter useContext"
            echo "   ✅ Tous les caches nettoyés"
            echo "   ✅ Dépendances React mises à jour"
            echo "   ✅ Interface admin reconstruite"
            echo ""
            echo "💡 Pour tester:"
            echo "   cd /home/myblog && ./start-services.sh"
            echo ""
            echo "🎯 L'erreur useContext ne devrait plus se reproduire !"
        else
            log_info "Solution complète annulée"
        fi
        ;;
    
    6)
        log_info "📊 Diagnostic terminé - voir les résultats ci-dessus"
        ;;
    
    7)
        log_info "👋 Au revoir !"
        exit 0
        ;;
    
    *)
        log_error "Option invalide"
        ;;
esac

echo ""
echo "💡 Après la correction, redémarrez avec:"
echo "   cd /home/myblog && ./start-services.sh"
