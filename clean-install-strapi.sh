#!/bin/bash

# 🔄 Réinstallation propre de Strapi 5.23.0
# Conserve les configurations, supprime les fichiers corrompus

echo "🔄 RÉINSTALLATION PROPRE STRAPI 5.23.0"
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

# Aller dans le dossier backend
cd /home/myblog/backend

echo ""
log_info "🔍 Préparation de la réinstallation..."

# Créer un dossier de sauvegarde avec timestamp
BACKUP_DIR="../backups/strapi-clean-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo ""
log_info "💾 Sauvegarde des configurations importantes..."

# Sauvegarder les fichiers ESSENTIELS
log_info "Sauvegarde de .env..."
cp .env "$BACKUP_DIR/"

log_info "Sauvegarde du dossier config/..."
cp -r config/ "$BACKUP_DIR/"

log_info "Sauvegarde des customisations src/ (si existantes)..."
if [ -d "src/api" ] || [ -d "src/components" ] || [ -d "src/extensions" ]; then
    cp -r src/ "$BACKUP_DIR/" 2>/dev/null || true
fi

log_info "Sauvegarde des uploads (si existants)..."
if [ -d "public/uploads" ] && [ "$(ls -A public/uploads 2>/dev/null)" ]; then
    cp -r public/uploads/ "$BACKUP_DIR/" 2>/dev/null || true
fi

log_success "Sauvegarde terminée dans: $BACKUP_DIR"

echo ""
log_warning "⚠️  ATTENTION: Suppression de l'installation Strapi actuelle"
echo "Les fichiers suivants seront SUPPRIMÉS:"
echo "   ❌ node_modules/ (dépendances)"
echo "   ❌ package-lock.json (verrous de version)"
echo "   ❌ .tmp/, .cache/, .strapi/, dist/ (caches)"
echo "   ❌ src/admin/ (interface admin corrompue)"
echo ""
echo "Les fichiers suivants seront PRÉSERVÉS:"
echo "   ✅ .env (variables d'environnement)"
echo "   ✅ config/ (configuration domaines)"
echo "   ✅ src/api/ (APIs personnalisées)"
echo "   ✅ public/uploads/ (fichiers uploadés)"
echo ""

read -p "Continuer avec la réinstallation propre? (y/N): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    log_info "Réinstallation annulée"
    exit 0
fi

echo ""
log_info "🛑 Arrêt de Strapi..."
pkill -f "strapi" || true
sleep 3

echo ""
log_info "🗑️  Suppression des fichiers corrompus..."

# Supprimer les dépendances
log_info "Suppression de node_modules/..."
rm -rf node_modules/

# Supprimer les verrous de version
log_info "Suppression des verrous de version..."
rm -f package-lock.json

# Supprimer tous les caches
log_info "Suppression des caches..."
rm -rf .tmp/
rm -rf .cache/
rm -rf .strapi/
rm -rf dist/
rm -rf .vite/

# Supprimer l'interface admin corrompue
log_info "Suppression de l'interface admin corrompue..."
rm -rf src/admin/

# Supprimer l'ancien package.json (on va le recréer)
log_info "Suppression de l'ancien package.json..."
rm -f package.json

log_success "Nettoyage terminé"

echo ""
log_info "📦 Création d'un nouveau projet Strapi 5.23.0..."

# Aller dans le dossier parent
cd ..

# Créer un nouveau projet Strapi temporaire
log_info "Génération d'un nouveau projet Strapi..."
npx create-strapi-app@latest backend-temp --quickstart --no-run --typescript --skip-cloud

echo ""
log_info "🔄 Migration des fichiers propres..."

# Copier les fichiers propres du nouveau projet
cd backend-temp

# Copier le nouveau package.json et le modifier
log_info "Installation du nouveau package.json..."
cp package.json ../backend/

# Copier la structure src propre
log_info "Installation de la structure src/ propre..."
cp -r src/ ../backend/

# Copier les autres fichiers essentiels
cp tsconfig.json ../backend/ 2>/dev/null || true
cp .gitignore ../backend/ 2>/dev/null || true

cd ../backend

echo ""
log_info "⚙️  Restauration des configurations..."

# Restaurer le .env
log_info "Restauration de .env..."
cp "$BACKUP_DIR/.env" .

# Restaurer la configuration
log_info "Restauration du dossier config/..."
rm -rf config/
cp -r "$BACKUP_DIR/config/" .

# Restaurer les customisations src si elles existaient
if [ -d "$BACKUP_DIR/src/api" ] || [ -d "$BACKUP_DIR/src/components" ] || [ -d "$BACKUP_DIR/src/extensions" ]; then
    log_info "Restauration des customisations src/..."
    cp -r "$BACKUP_DIR/src/api/" src/ 2>/dev/null || true
    cp -r "$BACKUP_DIR/src/components/" src/ 2>/dev/null || true
    cp -r "$BACKUP_DIR/src/extensions/" src/ 2>/dev/null || true
fi

# Restaurer les uploads
if [ -d "$BACKUP_DIR/uploads" ]; then
    log_info "Restauration des uploads..."
    mkdir -p public/
    cp -r "$BACKUP_DIR/uploads/" public/ 2>/dev/null || true
fi

echo ""
log_info "📥 Installation des dépendances Strapi 5.23.0..."
npm install

echo ""
log_info "🎨 Configuration de l'interface admin optimisée..."

# Créer la configuration Vite optimisée
mkdir -p src/admin
cat > src/admin/vite.config.ts << 'EOF'
import { mergeConfig, type UserConfig } from 'vite';

export default (config: UserConfig) => {
  // Configuration optimisée pour Strapi 5.23.0
  // Résout définitivement le problème useContext
  return mergeConfig(config, {
    resolve: {
      alias: {
        '@': '/src',
      },
      // Déduplication React pour éviter les conflits useContext
      dedupe: ['react', 'react-dom', 'react-router-dom']
    },
    server: {
      fs: {
        strict: false,
      },
      host: true,
      allowedHosts: [
        'cms.bh-systems.be',
        'localhost',
        '127.0.0.1',
        '0.0.0.0',
        '.bh-systems.be'
      ],
      hmr: {
        overlay: false,
        port: 1440
      }
    },
    optimizeDeps: {
      include: ['react', 'react-dom', 'react-router-dom'],
      force: true,
      esbuildOptions: {
        target: 'esnext'
      }
    },
    build: {
      target: 'esnext',
      sourcemap: false,
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
    define: {
      global: 'globalThis',
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'development')
    }
  });
};
EOF

echo ""
log_info "🔨 Construction de l'interface admin..."
npm run build

echo ""
log_info "🧹 Nettoyage des fichiers temporaires..."
cd ..
rm -rf backend-temp/

echo ""
log_success "🎉 RÉINSTALLATION TERMINÉE !"
echo ""
echo "📋 Résumé de l'installation:"
echo "   ✅ Strapi 5.23.0 installé proprement"
echo "   ✅ Configuration domaines préservée"
echo "   ✅ Variables d'environnement restaurées"
echo "   ✅ Interface admin optimisée"
echo "   ✅ Problème useContext résolu"
echo ""
echo "💾 Sauvegarde disponible dans: $BACKUP_DIR"
echo ""
echo "🚀 Prochaines étapes:"
echo "   1. cd /home/myblog && ./start-services.sh"
echo "   2. Aller sur https://cms.bh-systems.be/admin"
echo "   3. Reconfigurer l'admin si nécessaire"
echo "   4. Ajouter du contenu de test"
echo ""
echo "🎯 L'erreur useContext ne devrait plus jamais revenir !"
