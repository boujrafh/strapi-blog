#!/bin/bash

# 🧪 Test final du nouveau Strapi 5.23.0

echo "🧪 TEST FINAL STRAPI 5.23.0"
echo "============================"

cd /home/myblog/backend-new

echo ""
echo "🔄 Redémarrage propre..."
pkill -f "strapi" || true
sleep 2

echo "🧹 Nettoyage des caches..."
rm -rf .tmp/ .strapi/ dist/ node_modules/.vite/

echo "🚀 Démarrage de Strapi..."
npm run develop &

echo ""
echo "⏳ Attente du démarrage (15 secondes)..."
sleep 15

echo ""
echo "🧪 Tests d'accès..."

# Test de l'endpoint admin
admin_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1440/admin)
echo "Status /admin: $admin_status"

# Test de l'endpoint init
init_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1440/admin/init)
echo "Status /admin/init: $init_status"

echo ""
echo "✅ Tests terminés"
echo ""
echo "🌐 Interface admin disponible sur:"
echo "   https://cms.bh-systems.be/admin"
