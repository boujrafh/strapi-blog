#!/bin/bash

# 🧪 Test de l'installation Strapi ultra-propre

echo "🧪 TEST INSTALLATION ULTRA-PROPRE"
echo "================================="

cd /home/myblog/backend

echo ""
echo "📦 Version installée:"
grep '"@strapi/strapi"' package.json | cut -d'"' -f4

echo ""
echo "🚀 Démarrage du test..."

# Démarrer Strapi en arrière-plan
npm run develop &
STRAPI_PID=$!

echo "⏳ Attente du démarrage (20 secondes)..."
sleep 20

echo ""
echo "🧪 Tests d'accès:"

# Test basic
echo -n "   localhost:1440 : "
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1440 2>/dev/null || echo "000")
if [ "$status" = "200" ] || [ "$status" = "302" ]; then
    echo "✅ OK ($status)"
else
    echo "❌ Erreur ($status)"
fi

# Test admin
echo -n "   /admin : "
admin_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1440/admin 2>/dev/null || echo "000")
if [ "$admin_status" = "200" ]; then
    echo "✅ OK ($admin_status)"
else
    echo "❌ Erreur ($admin_status)"
fi

# Test init
echo -n "   /admin/init : "
init_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1440/admin/init 2>/dev/null || echo "000")
if [ "$init_status" = "200" ]; then
    echo "✅ OK ($init_status)"
else
    echo "❌ Erreur ($init_status)"
fi

echo ""
echo "📊 Processus Strapi:"
ps aux | grep strapi | grep -v grep | head -3

echo ""
echo "🎯 RÉSULTAT:"
if [ "$admin_status" = "200" ] && [ "$init_status" = "200" ]; then
    echo "✅ SUCCÈS ! Strapi fonctionne parfaitement"
    echo ""
    echo "🌐 Interface admin accessible:"
    echo "   http://localhost:1440/admin"
    echo ""
    echo "💡 Prochaines étapes si tout va bien:"
    echo "   1. Créer le premier admin"
    echo "   2. Ajouter du contenu de test"
    echo "   3. Vérifier la stabilité (pas d'erreur useContext)"
    echo "   4. Puis ajouter PostgreSQL et domaines personnalisés"
else
    echo "❌ PROBLÈME détecté - besoin de diagnostic"
fi

echo ""
echo "Pour arrêter Strapi: kill $STRAPI_PID"
