#!/bin/bash

# 📊 Script de visualisation des logs en temps réel
echo "📊 Visualisation des logs en temps réel"
echo "======================================"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_DIR="/home/myblog/logs"

# Vérifier que le dossier logs existe
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${RED}❌ Dossier logs non trouvé: $LOG_DIR${NC}"
    echo "   Exécutez d'abord: ./init-logs.sh"
    exit 1
fi

show_menu() {
    clear
    echo -e "${BLUE}📊 Visualisation des logs - Menu${NC}"
    echo "================================="
    echo ""
    echo "1️⃣  📱 Backend Strapi (temps réel)"
    echo "2️⃣  🌐 Frontend React Router (temps réel)"
    echo "3️⃣  🔍 Monitoring Strapi (temps réel)"
    echo "4️⃣  ⚡ Performance (temps réel)"
    echo "5️⃣  🛠️  Système général (temps réel)"
    echo "6️⃣  📊 Tous les logs (temps réel)"
    echo ""
    echo "7️⃣  📋 Résumé des logs (statique)"
    echo "8️⃣  🔍 Rechercher dans les logs"
    echo "9️⃣  📈 Statistiques des logs"
    echo "🔟  📁 Ouvrir dossier logs"
    echo ""
    echo "0️⃣  Quitter"
    echo ""
    read -p "Choisissez une option (0-10): " choice
    
    case $choice in
        1) 
            echo -e "${GREEN}📱 Suivi du backend Strapi...${NC}"
            echo "   Appuyez sur Ctrl+C pour revenir au menu"
            sleep 2
            tail -f "$LOG_DIR/backend.log"
            ;;
        2) 
            echo -e "${GREEN}🌐 Suivi du frontend React Router...${NC}"
            echo "   Appuyez sur Ctrl+C pour revenir au menu"
            sleep 2
            tail -f "$LOG_DIR/frontend.log"
            ;;
        3) 
            echo -e "${GREEN}🔍 Suivi du monitoring Strapi...${NC}"
            echo "   Appuyez sur Ctrl+C pour revenir au menu"
            sleep 2
            tail -f "$LOG_DIR/strapi-monitor.log"
            ;;
        4) 
            echo -e "${GREEN}⚡ Suivi des performances...${NC}"
            echo "   Appuyez sur Ctrl+C pour revenir au menu"
            sleep 2
            tail -f "$LOG_DIR/performance.log"
            ;;
        5) 
            echo -e "${GREEN}🛠️ Suivi du système...${NC}"
            echo "   Appuyez sur Ctrl+C pour revenir au menu"
            sleep 2
            tail -f "$LOG_DIR/system.log"
            ;;
        6) 
            echo -e "${GREEN}📊 Suivi de tous les logs...${NC}"
            echo "   Appuyez sur Ctrl+C pour revenir au menu"
            sleep 2
            tail -f "$LOG_DIR"/*.log
            ;;
        7) show_log_summary ;;
        8) search_in_logs ;;
        9) show_log_stats ;;
        10) 
            echo -e "${GREEN}📁 Ouverture du dossier logs...${NC}"
            ls -la "$LOG_DIR"
            echo ""
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        0) exit 0 ;;
        *) 
            echo -e "${RED}❌ Option invalide${NC}"
            sleep 1
            ;;
    esac
}

show_log_summary() {
    clear
    echo -e "${BLUE}📋 Résumé des logs${NC}"
    echo "=================="
    echo ""
    
    for logfile in "$LOG_DIR"/*.log; do
        if [ -f "$logfile" ]; then
            local filename=$(basename "$logfile")
            local size=$(du -h "$logfile" | cut -f1)
            local lines=$(wc -l < "$logfile")
            local last_modified=$(stat -c %y "$logfile" | cut -d. -f1)
            
            echo -e "${GREEN}📄 $filename${NC}"
            echo "   📏 Taille: $size"
            echo "   📊 Lignes: $lines"
            echo "   🕐 Modifié: $last_modified"
            
            # Afficher les dernières lignes significatives
            echo "   📝 Dernières entrées:"
            tail -3 "$logfile" | while read line; do
                echo "      $line"
            done
            echo ""
        fi
    done
    
    read -p "Appuyez sur Entrée pour continuer..."
}

search_in_logs() {
    clear
    echo -e "${BLUE}🔍 Recherche dans les logs${NC}"
    echo "=========================="
    echo ""
    
    read -p "🔎 Entrez le terme à rechercher: " search_term
    
    if [ -z "$search_term" ]; then
        echo -e "${RED}❌ Terme de recherche vide${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${GREEN}🔍 Recherche de '$search_term' dans tous les logs...${NC}"
    echo ""
    
    local found=false
    for logfile in "$LOG_DIR"/*.log; do
        if [ -f "$logfile" ]; then
            local matches=$(grep -n -i "$search_term" "$logfile" 2>/dev/null)
            if [ -n "$matches" ]; then
                found=true
                echo -e "${YELLOW}📄 $(basename "$logfile"):${NC}"
                echo "$matches" | head -10  # Limiter à 10 résultats par fichier
                echo ""
            fi
        fi
    done
    
    if [ "$found" = false ]; then
        echo -e "${RED}❌ Aucun résultat trouvé pour '$search_term'${NC}"
    fi
    
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

show_log_stats() {
    clear
    echo -e "${BLUE}📈 Statistiques des logs${NC}"
    echo "======================="
    echo ""
    
    # Statistiques générales
    local total_files=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
    local total_size=$(du -sh "$LOG_DIR" | cut -f1)
    local total_lines=$(cat "$LOG_DIR"/*.log 2>/dev/null | wc -l)
    
    echo -e "${GREEN}📊 Vue d'ensemble:${NC}"
    echo "   📁 Fichiers de logs: $total_files"
    echo "   💾 Taille totale: $total_size"
    echo "   📄 Lignes totales: $total_lines"
    echo ""
    
    # Statistiques par type de log
    echo -e "${GREEN}📂 Détails par fichier:${NC}"
    for logfile in "$LOG_DIR"/*.log; do
        if [ -f "$logfile" ]; then
            local filename=$(basename "$logfile")
            local size=$(du -h "$logfile" | cut -f1)
            local lines=$(wc -l < "$logfile")
            printf "   %-20s %8s %10s lignes\n" "$filename" "$size" "$lines"
        fi
    done
    echo ""
    
    # Recherche d'erreurs
    echo -e "${GREEN}🚨 Analyse d'erreurs:${NC}"
    local error_count=$(grep -i "error\|exception\|fatal\|critical" "$LOG_DIR"/*.log 2>/dev/null | wc -l)
    local warning_count=$(grep -i "warning\|warn" "$LOG_DIR"/*.log 2>/dev/null | wc -l)
    
    echo "   ❌ Erreurs détectées: $error_count"
    echo "   ⚠️  Avertissements: $warning_count"
    
    if [ "$error_count" -gt 0 ]; then
        echo ""
        echo -e "${RED}🚨 Dernières erreurs:${NC}"
        grep -i "error\|exception\|fatal\|critical" "$LOG_DIR"/*.log 2>/dev/null | tail -5
    fi
    
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction pour nettoyer l'affichage à la sortie
cleanup() {
    clear
    echo -e "${GREEN}👋 Au revoir !${NC}"
    exit 0
}

# Capturer Ctrl+C pour revenir au menu
trap 'echo -e "\n${YELLOW}↩️ Retour au menu...${NC}"; sleep 1' INT

# Boucle principale
while true; do
    show_menu
done
