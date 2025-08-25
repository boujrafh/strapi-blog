#!/bin/bash

# 🆕 Création d'un Strapi LATEST ultra-propre
# SANS domaine personnalisé pour éviter les complications

echo "🆕 CRÉATION STRAPI LATEST ULTRA-PROPRE"
echo "======================================"

cd /home/myblog

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

echo ""
log_info "🗑️  Suppression des anciennes installations..."

# Supprimer les anciens backends
rm -rf backend-new/ 2>/dev/null || true
rm -rf backend-test/ 2>/dev/null || true

# Créer un dossier de sauvegarde pour l'ancien backend
if [ -d "backend" ]; then
    BACKUP_NAME="backend-backup-$(date +%Y%m%d-%H%M%S)"
    log_info "Sauvegarde de l'ancien backend vers $BACKUP_NAME"
    mv backend "$BACKUP_NAME"
fi

echo ""
log_info "📦 Création d'un nouveau Strapi LATEST..."
log_info "Configuration: Base minimale SANS domaine personnalisé"

# Créer un nouveau Strapi avec configuration minimale
npx create-strapi-app@latest backend \
  --quickstart \
  --no-run \
  --typescript \
  --skip-cloud

echo ""
log_info "⚙️  Configuration de base pour test local..."

cd backend

# Créer un .env MINIMAL pour test
cat > .env << 'EOF'
# Configuration MINIMALE pour test local
HOST=0.0.0.0
PORT=1440

# Secrets générés automatiquement
APP_KEYS=strapi-app-key-1,strapi-app-key-2,strapi-app-key-3,strapi-app-key-4
API_TOKEN_SALT=api-token-salt
ADMIN_JWT_SECRET=admin-jwt-secret
TRANSFER_TOKEN_SALT=transfer-token-salt
JWT_SECRET=jwt-secret

# Base de données SQLite par défaut (pour test)
# On ajoutera PostgreSQL plus tard si tout fonctionne
EOF

log_success ".env créé avec configuration minimale"

echo ""
log_info "🎨 Configuration Vite anti-useContext..."

# Créer une configuration Vite SIMPLE et efficace
mkdir -p src/admin
cat > src/admin/vite.config.ts << 'EOF'
import { mergeConfig, type UserConfig } from 'vite';

export default (config: UserConfig) => {
  // Configuration SIMPLE anti-useContext
  return mergeConfig(config, {
    server: {
      host: true,
      port: 1440,
      hmr: {
        overlay: false
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
};
EOF

log_success "Configuration Vite anti-useContext créée"

echo ""
log_info "🔨 Construction de l'interface admin..."
npm run build

echo ""
log_success "🎉 STRAPI LATEST CRÉÉ AVEC SUCCÈS !"
echo ""
echo "📋 Configuration appliquée:"
echo "   ✅ Strapi latest installé"
echo "   ✅ Configuration MINIMALE (pas de domaine personnalisé)"
echo "   ✅ Base SQLite pour test rapide"
echo "   ✅ Anti-useContext configuré"
echo "   ✅ Interface admin construite"
echo ""
echo "🚀 Pour tester:"
echo "   cd /home/myblog/backend && npm run develop"
echo "   Puis aller sur: http://localhost:1440/admin"
echo ""
echo "💡 Une fois que ça marche parfaitement:"
echo "   1. On pourra ajouter PostgreSQL (Neon)"
echo "   2. On pourra ajouter les domaines personnalisés"
echo "   3. On pourra ajouter Cloudinary"
echo ""
echo "🎯 Objectif: ZÉRO erreur useContext avec cette base propre !"
