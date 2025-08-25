#!/bin/bash

# 🔧 Script de diagnostic avancé pour les problèmes Strapi/React
echo "🔧 Diagnostic avancé Strapi/React"
echo "================================"

# Couleurs
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction pour vérifier les erreurs React courantes
check_react_errors() {
    echo ""
    echo "🔍 Analyse des erreurs React/Context..."
    echo "======================================"
    
    local strapi_logs="/home/myblog/backend/logs/strapi.log"
    local browser_errors=()
    
    # Vérifier les erreurs de contexte React
    echo ""
    log_info "🔍 Recherche d'erreurs de contexte React..."
    
    # Erreurs courantes à détecter
    local error_patterns=(
        "Cannot read properties of null.*useContext"
        "useContext.*null"
        "Router.*useContext"
        "TypeError.*useContext"
        "Uncaught TypeError"
        "Cannot read properties of undefined"
        "Maximum call stack size exceeded"
        "Memory leak"
        "FATAL ERROR"
        "out of memory"
    )
    
    # Analyser les logs du navigateur via curl des pages admin
    log_info "Test de l'interface admin Strapi..."
    
    local admin_response=$(curl -s -w "%{http_code}" --max-time 15 "http://localhost:1440/admin" 2>/dev/null)
    local http_code="${admin_response: -3}"
    local response_body="${admin_response%???}"
    
    echo "   📊 Code réponse: $http_code"
    
    if [ "$http_code" != "200" ] && [ "$http_code" != "302" ]; then
        log_error "Interface admin non accessible (Code: $http_code)"
        return 1
    fi
    
    # Vérifier la structure de la réponse
    if echo "$response_body" | grep -q "useContext"; then
        log_warning "Références useContext détectées dans la réponse"
    fi
    
    # Vérifier les erreurs JavaScript dans les logs Strapi
    if [ -f "$strapi_logs" ]; then
        log_info "Analyse des logs Strapi..."
        
        for pattern in "${error_patterns[@]}"; do
            local count=$(grep -c "$pattern" "$strapi_logs" 2>/dev/null || echo "0")
            if [ "$count" -gt 0 ]; then
                log_warning "Pattern '$pattern': $count occurrences"
                
                # Afficher les 2 dernières occurrences
                echo "   Dernières occurrences:"
                grep "$pattern" "$strapi_logs" | tail -2 | while read line; do
                    echo "     $line"
                done
            fi
        done
    else
        log_warning "Logs Strapi non trouvés ($strapi_logs)"
    fi
}

# Fonction pour vérifier l'état de la mémoire
check_memory_status() {
    echo ""
    echo "🧠 Analyse de l'utilisation mémoire..."
    echo "===================================="
    
    local strapi_pid=$(pgrep -f "strapi.*develop")
    
    if [ -z "$strapi_pid" ]; then
        log_error "Processus Strapi non trouvé"
        return 1
    fi
    
    # Statistiques mémoire détaillées
    local memory_info=$(ps -p $strapi_pid -o pid,ppid,%mem,%cpu,rss,vsz,etime,cmd --no-headers)
    echo "📊 Processus Strapi (PID: $strapi_pid):"
    echo "$memory_info"
    
    # Mémoire RSS en MB
    local rss_kb=$(echo "$memory_info" | awk '{print $5}')
    local rss_mb=$((rss_kb / 1024))
    
    echo ""
    echo "📊 Détails mémoire:"
    echo "   🔹 Mémoire physique (RSS): ${rss_mb} MB"
    echo "   🔹 Mémoire virtuelle (VSZ): $(echo "$memory_info" | awk '{print $6/1024}' | cut -d. -f1) MB"
    echo "   🔹 Pourcentage mémoire: $(echo "$memory_info" | awk '{print $3}')%"
    echo "   🔹 Pourcentage CPU: $(echo "$memory_info" | awk '{print $4}')%"
    echo "   🔹 Temps d'exécution: $(echo "$memory_info" | awk '{print $7}')"
    
    # Alerte si mémoire élevée
    if [ "$rss_mb" -gt 1000 ]; then
        log_warning "Utilisation mémoire élevée: ${rss_mb} MB"
        log_info "Recommandation: Redémarrage préventif recommandé"
    elif [ "$rss_mb" -gt 500 ]; then
        log_warning "Utilisation mémoire modérée: ${rss_mb} MB"
    else
        log_success "Utilisation mémoire normale: ${rss_mb} MB"
    fi
    
    # Vérifier les fuites mémoire potentielles
    echo ""
    echo "🔍 Recherche de fuites mémoire..."
    
    # Analyser l'historique d'utilisation si disponible
    if [ -f "/home/myblog/logs/strapi-monitor.log" ]; then
        local memory_trend=$(grep "Mémoire:" /home/myblog/logs/strapi-monitor.log | tail -5)
        if [ -n "$memory_trend" ]; then
            echo "📈 Tendance mémoire (5 dernières mesures):"
            echo "$memory_trend"
        fi
    fi
}

# Fonction pour vérifier les dépendances Node.js
check_node_dependencies() {
    echo ""
    echo "📦 Vérification des dépendances Node.js..."
    echo "========================================="
    
    cd /home/myblog/backend
    
    # Vérifier la version Node.js
    local node_version=$(node --version)
    local npm_version=$(npm --version)
    
    echo "📊 Versions installées:"
    echo "   🔹 Node.js: $node_version"
    echo "   🔹 NPM: $npm_version"
    
    # Vérifier les versions recommandées pour Strapi v5
    local node_major=$(echo $node_version | cut -d'.' -f1 | tr -d 'v')
    
    if [ "$node_major" -lt 18 ]; then
        log_error "Version Node.js trop ancienne. Strapi v5 requiert Node.js 18+"
    elif [ "$node_major" -ge 18 ] && [ "$node_major" -le 20 ]; then
        log_success "Version Node.js compatible avec Strapi v5"
    else
        log_warning "Version Node.js très récente, vérifiez la compatibilité"
    fi
    
    # Vérifier les vulnérabilités
    echo ""
    log_info "🔍 Audit de sécurité NPM..."
    local audit_output=$(npm audit 2>/dev/null)
    local vulnerabilities=$(echo "$audit_output" | grep "vulnerabilities" | tail -1)
    
    if [ -n "$vulnerabilities" ]; then
        echo "   $vulnerabilities"
        if echo "$audit_output" | grep -q "high\|critical"; then
            log_warning "Vulnérabilités critiques détectées"
            echo "   💡 Exécutez: npm audit fix"
        fi
    else
        log_success "Aucune vulnérabilité détectée"
    fi
    
    # Vérifier les dépendances obsolètes
    echo ""
    log_info "🔍 Vérification des packages obsolètes..."
    local outdated=$(npm outdated 2>/dev/null)
    if [ -n "$outdated" ]; then
        echo "$outdated"
        log_warning "Packages obsolètes détectés"
    else
        log_success "Toutes les dépendances sont à jour"
    fi
}

# Fonction pour vérifier la configuration Vite/Strapi
check_vite_config() {
    echo ""
    echo "⚡ Vérification configuration Vite..."
    echo "===================================="
    
    local vite_config="/home/myblog/backend/src/admin/vite.config.ts"
    
    if [ -f "$vite_config" ]; then
        log_success "Fichier vite.config.ts trouvé"
        
        # Vérifier la configuration allowedHosts
        if grep -q "allowedHosts" "$vite_config"; then
            log_success "Configuration allowedHosts présente"
            echo "   Configuration:"
            grep -A 5 -B 2 "allowedHosts" "$vite_config"
        else
            log_error "Configuration allowedHosts manquante"
            echo ""
            echo "💡 Solution: Ajouter allowedHosts dans vite.config.ts:"
            echo "   server: {"
            echo "     allowedHosts: ['cms.bh-systems.be', 'localhost']"
            echo "   }"
        fi
        
        # Vérifier la configuration du serveur
        if grep -q "server:" "$vite_config"; then
            log_success "Configuration serveur présente"
        else
            log_warning "Configuration serveur manquante ou incomplète"
        fi
    else
        log_error "Fichier vite.config.ts non trouvé"
        echo "   Emplacement attendu: $vite_config"
    fi
}

# Fonction pour tester la connectivité réseau
check_network_connectivity() {
    echo ""
    echo "🌐 Test de connectivité réseau..."
    echo "==============================="
    
    # Test connectivité locale
    log_info "🔍 Test connectivité locale..."
    
    if nc -z localhost 1440 2>/dev/null; then
        log_success "Port 1440 (Strapi) accessible"
    else
        log_error "Port 1440 (Strapi) non accessible"
    fi
    
    if nc -z localhost 5173 2>/dev/null; then
        log_success "Port 5173 (Frontend) accessible"
    else
        log_error "Port 5173 (Frontend) non accessible"
    fi
    
    # Test API Strapi
    echo ""
    log_info "🔍 Test API Strapi..."
    
    local api_test=$(curl -s --max-time 10 "http://localhost:1440/api/posts" 2>/dev/null)
    if echo "$api_test" | jq . >/dev/null 2>&1; then
        log_success "API Strapi fonctionne (JSON valide)"
        local post_count=$(echo "$api_test" | jq '.data | length' 2>/dev/null || echo "0")
        echo "   🔹 Nombre de posts: $post_count"
    else
        log_error "API Strapi ne retourne pas de JSON valide"
        echo "   Réponse: $(echo "$api_test" | head -c 200)..."
    fi
    
    # Test des domaines de production si configurés
    echo ""
    log_info "🔍 Test des domaines de production..."
    
    if ping -c 1 cms.bh-systems.be >/dev/null 2>&1; then
        log_success "Domaine cms.bh-systems.be résolvable"
        
        local prod_test=$(curl -s -w "%{http_code}" --max-time 10 "https://cms.bh-systems.be/admin" 2>/dev/null)
        local prod_code="${prod_test: -3}"
        
        if [ "$prod_code" = "200" ] || [ "$prod_code" = "302" ]; then
            log_success "CMS production accessible (Code: $prod_code)"
        else
            log_warning "CMS production problématique (Code: $prod_code)"
        fi
    else
        log_warning "Domaine cms.bh-systems.be non résolvable"
    fi
}

# Fonction pour générer un rapport de diagnostic
generate_report() {
    echo ""
    echo "📋 Génération du rapport de diagnostic..."
    echo "========================================"
    
    local report_file="/home/myblog/logs/diagnostic-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "🔧 RAPPORT DE DIAGNOSTIC STRAPI/REACT"
        echo "====================================="
        echo "Date: $(date)"
        echo "Hostname: $(hostname)"
        echo ""
        
        echo "📊 ÉTAT DES PROCESSUS:"
        echo "---------------------"
        ps aux | grep -E "(strapi|node|npm)" | grep -v grep
        echo ""
        
        echo "📊 PORTS OCCUPÉS:"
        echo "----------------"
        lsof -i:1440 2>/dev/null || echo "Port 1440: Libre"
        lsof -i:5173 2>/dev/null || echo "Port 5173: Libre"
        echo ""
        
        echo "📊 UTILISATION MÉMOIRE:"
        echo "----------------------"
        free -h
        echo ""
        
        echo "📊 ESPACE DISQUE:"
        echo "----------------"
        df -h /home/myblog
        echo ""
        
        echo "📊 LOGS RÉCENTS (dernières 10 lignes):"
        echo "-------------------------------------"
        if [ -f "/home/myblog/backend/logs/strapi.log" ]; then
            echo "=== Strapi logs ==="
            tail -10 /home/myblog/backend/logs/strapi.log
        fi
        
        if [ -f "/home/myblog/logs/strapi-monitor.log" ]; then
            echo "=== Monitor logs ==="
            tail -10 /home/myblog/logs/strapi-monitor.log
        fi
        
        echo ""
        echo "📊 CONFIGURATION VITE:"
        echo "---------------------"
        if [ -f "/home/myblog/backend/src/admin/vite.config.ts" ]; then
            cat /home/myblog/backend/src/admin/vite.config.ts
        else
            echo "Fichier vite.config.ts non trouvé"
        fi
        
    } > "$report_file"
    
    log_success "Rapport généré: $report_file"
    echo "   📄 Consultez le rapport avec: cat $report_file"
}

# Menu principal
show_menu() {
    echo ""
    echo "🔧 Diagnostic Strapi/React - Menu"
    echo "================================"
    echo ""
    echo "1️⃣  Diagnostic complet"
    echo "2️⃣  Erreurs React/Context"
    echo "3️⃣  Analyse mémoire"
    echo "4️⃣  Dépendances Node.js"
    echo "5️⃣  Configuration Vite"
    echo "6️⃣  Connectivité réseau"
    echo "7️⃣  Générer rapport"
    echo "8️⃣  Quitter"
    echo ""
    read -p "Choisissez une option (1-8): " choice
    
    case $choice in
        1)
            check_react_errors
            check_memory_status
            check_node_dependencies
            check_vite_config
            check_network_connectivity
            ;;
        2) check_react_errors ;;
        3) check_memory_status ;;
        4) check_node_dependencies ;;
        5) check_vite_config ;;
        6) check_network_connectivity ;;
        7) generate_report ;;
        8) exit 0 ;;
        *) log_error "Option invalide" ;;
    esac
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
    "full"|"all") 
        check_react_errors
        check_memory_status
        check_node_dependencies
        check_vite_config
        check_network_connectivity
        generate_report
        ;;
    "react") check_react_errors ;;
    "memory") check_memory_status ;;
    "deps") check_node_dependencies ;;
    "vite") check_vite_config ;;
    "network") check_network_connectivity ;;
    "report") generate_report ;;
    *)
        echo "Usage: $0 {menu|full|react|memory|deps|vite|network|report}"
        echo ""
        echo "Options:"
        echo "  menu     - Menu interactif (défaut)"
        echo "  full     - Diagnostic complet"
        echo "  react    - Analyse erreurs React/Context"
        echo "  memory   - Analyse utilisation mémoire"
        echo "  deps     - Vérification dépendances Node.js"
        echo "  vite     - Vérification configuration Vite"
        echo "  network  - Test connectivité réseau"
        echo "  report   - Générer rapport détaillé"
        exit 1
        ;;
esac
