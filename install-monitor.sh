#!/bin/bash

# 🛠️ Script d'installation du monitoring Strapi
echo "🛠️ Installation du monitoring Strapi"
echo "===================================="

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Vérifier les permissions root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté en tant que root"
    echo "   Utilisez: sudo ./install-monitor.sh"
    exit 1
fi

# 1. Installer les dépendances si nécessaires
log_info "Vérification des dépendances..."

# Installer jq si pas présent
if ! command -v jq &> /dev/null; then
    log_info "Installation de jq..."
    apt update && apt install -y jq
fi

# Installer bc si pas présent
if ! command -v bc &> /dev/null; then
    log_info "Installation de bc..."
    apt update && apt install -y bc
fi

# Installer netcat si pas présent
if ! command -v nc &> /dev/null; then
    log_info "Installation de netcat..."
    apt update && apt install -y netcat-openbsd
fi

log_success "Dépendances vérifiées"

# 2. Créer les dossiers nécessaires
log_info "Création des dossiers de logs..."
mkdir -p /home/myblog/logs
chown root:root /home/myblog/logs
chmod 755 /home/myblog/logs
log_success "Dossiers créés"

# 3. Installer le service systemd
log_info "Installation du service systemd..."
cp /home/myblog/strapi-monitor.service /etc/systemd/system/
systemctl daemon-reload
log_success "Service systemd installé"

# 4. Activer et démarrer le service
log_info "Activation du service..."
systemctl enable strapi-monitor.service
log_success "Service activé pour démarrage automatique"

echo ""
echo "🎉 Installation terminée !"
echo ""
echo "📋 Commandes utiles :"
echo ""
echo "🔹 Démarrer le monitoring :"
echo "   sudo systemctl start strapi-monitor"
echo ""
echo "🔹 Arrêter le monitoring :"
echo "   sudo systemctl stop strapi-monitor"
echo ""
echo "🔹 Voir le statut :"
echo "   sudo systemctl status strapi-monitor"
echo ""
echo "🔹 Voir les logs en temps réel :"
echo "   sudo journalctl -u strapi-monitor -f"
echo ""
echo "🔹 Commandes manuelles :"
echo "   ./monitor-strapi.sh check    # Vérification ponctuelle"
echo "   ./monitor-strapi.sh restart  # Redémarrage forcé"
echo "   ./monitor-strapi.sh stats    # Statistiques"
echo "   ./monitor-strapi.sh logs     # Logs de monitoring"
echo ""

# Proposer de démarrer le service
read -p "🤔 Voulez-vous démarrer le monitoring maintenant ? (Y/n): " start_service

if [[ $start_service =~ ^[Nn]$ ]]; then
    log_info "Service non démarré. Vous pouvez le démarrer plus tard avec:"
    echo "   sudo systemctl start strapi-monitor"
else
    log_info "Démarrage du service..."
    systemctl start strapi-monitor
    sleep 2
    
    if systemctl is-active --quiet strapi-monitor; then
        log_success "✅ Service de monitoring démarré avec succès !"
        echo ""
        echo "📊 Statut actuel :"
        systemctl status strapi-monitor --no-pager -l
    else
        log_warning "⚠️ Problème lors du démarrage. Vérifiez les logs :"
        echo "   sudo journalctl -u strapi-monitor -n 20"
    fi
fi
