#!/bin/bash

# Script pour déployer SEULEMENT le frontend blog.bh-systems.be
echo "🎨 Déploiement frontend blog.bh-systems.be"
echo "============================================"

# Vérifications préliminaires
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté en tant que root (sudo)"
    exit 1
fi

echo "📋 Étapes de déploiement frontend :"
echo "1. 🛑 Arrêt des services Docker concurrents"
echo "2. 📂 Configuration nginx pour le blog uniquement"
echo "3. 🚀 Démarrage des services"
echo "4. ✅ Test du frontend"
echo ""

# Arrêter Docker si nécessaire
echo "🛑 Vérification des services Docker..."
if docker ps -q | grep -q .; then
    echo "⚠️  Arrêt temporaire des conteneurs Docker..."
    docker stop $(docker ps -q) 2>/dev/null || true
fi

# Copier seulement la configuration blog
echo "📂 Configuration nginx pour le blog..."
cp /home/myblog/nginx-blog.conf /etc/nginx/sites-available/blog.bh-systems.be

# Désactiver les autres sites
echo "🔇 Désactivation des autres sites..."
rm -f /etc/nginx/sites-enabled/cms.stib-mivb.be 2>/dev/null || true
rm -f /etc/nginx/sites-enabled/api.bh-systems.be 2>/dev/null || true
rm -f /etc/nginx/sites-enabled/dev-api.bh-systems.be 2>/dev/null || true

# Activer seulement le blog
echo "🔗 Activation du site blog..."
ln -sf /etc/nginx/sites-available/blog.bh-systems.be /etc/nginx/sites-enabled/

# Tester la configuration
echo "✅ Test de la configuration nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration nginx valide !"
    
    # Démarrer nginx
    echo "🔄 Démarrage nginx..."
    systemctl start nginx
    systemctl reload nginx
    
    # Démarrer le backend Strapi en arrière-plan
    echo "🚀 Démarrage du backend Strapi..."
    cd /home/myblog/backend
    npm run develop > /tmp/strapi.log 2>&1 &
    STRAPI_PID=$!
    echo "📝 Strapi PID: $STRAPI_PID"
    
    # Attendre que Strapi démarre
    echo "⏳ Attente du démarrage de Strapi (30s)..."
    sleep 30
    
    # Démarrer le frontend
    echo "🎨 Démarrage du frontend..."
    cd /home/myblog/frontend
    npm run dev > /tmp/frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo "📝 Frontend PID: $FRONTEND_PID"
    
    # Attendre que le frontend démarre
    echo "⏳ Attente du démarrage du frontend (15s)..."
    sleep 15
    
    echo ""
    echo "🎉 ✅ DÉPLOIEMENT FRONTEND RÉUSSI !"
    echo ""
    echo "🌐 Votre blog est maintenant accessible sur :"
    echo "   🎨 https://blog.bh-systems.be"
    echo ""
    echo "📊 Processus en cours :"
    echo "   📦 Strapi PID: $STRAPI_PID (backend)"
    echo "   🎨 Frontend PID: $FRONTEND_PID (frontend)"
    echo ""
    echo "📝 Logs disponibles :"
    echo "   📦 Backend: tail -f /tmp/strapi.log"
    echo "   🎨 Frontend: tail -f /tmp/frontend.log"
    echo ""
    echo "🛑 Pour arrêter les services :"
    echo "   kill $STRAPI_PID $FRONTEND_PID"
    
else
    echo "❌ Erreur dans la configuration nginx !"
    echo "🔍 Vérifiez les logs avec: nginx -t"
    exit 1
fi
