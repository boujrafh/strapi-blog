#!/bin/bash

# 🔍 Script de capture et analyse des erreurs côté client Strapi
echo "🔍 Capture d'erreurs côté client Strapi"
echo "======================================"

# Configuration
STRAPI_ADMIN_URL="https://cms.bh-systems.be/admin"
LOCAL_ADMIN_URL="http://localhost:1440/admin"
LOG_DIR="/home/myblog/logs"
CLIENT_ERRORS_LOG="$LOG_DIR/client-errors.log"
BROWSER_LOG="$LOG_DIR/browser-console.log"

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

# Fonction pour logger avec timestamp
log_to_file() {
    local logfile=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$logfile"
}

# Créer les fichiers de logs s'ils n'existent pas
mkdir -p "$LOG_DIR"
touch "$CLIENT_ERRORS_LOG"
touch "$BROWSER_LOG"

# Fonction pour capturer les erreurs côté client avec headless browser
capture_client_errors() {
    local url=$1
    local test_name=$2
    
    log_info "🔍 Test de $test_name: $url"
    
    # Créer un script JavaScript pour capturer les erreurs
    local js_script="/tmp/capture_errors.js"
    cat > "$js_script" << 'EOF'
const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    });
    
    const page = await browser.newPage();
    
    // Capturer les erreurs de la console
    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            errors.push({
                type: 'console-error',
                text: msg.text(),
                location: msg.location()
            });
        }
    });
    
    // Capturer les erreurs JavaScript
    page.on('pageerror', error => {
        errors.push({
            type: 'page-error',
            message: error.message,
            stack: error.stack
        });
    });
    
    // Capturer les erreurs de requête
    page.on('requestfailed', request => {
        errors.push({
            type: 'request-failed',
            url: request.url(),
            failure: request.failure()
        });
    });
    
    try {
        await page.goto(process.argv[2], { 
            waitUntil: 'networkidle0',
            timeout: 30000 
        });
        
        // Attendre quelques secondes pour que les erreurs React se manifestent
        await page.waitForTimeout(5000);
        
        // Essayer de naviguer vers le content-manager
        try {
            await page.click('a[href*="content-manager"]', { timeout: 5000 });
            await page.waitForTimeout(3000);
        } catch (e) {
            // Pas grave si on ne peut pas cliquer
        }
        
    } catch (error) {
        errors.push({
            type: 'navigation-error',
            message: error.message
        });
    }
    
    // Afficher les erreurs capturées
    if (errors.length > 0) {
        console.log('ERRORS_FOUND:');
        errors.forEach(error => {
            console.log(JSON.stringify(error));
        });
    } else {
        console.log('NO_ERRORS_FOUND');
    }
    
    await browser.close();
})();
EOF
    
    # Vérifier si puppeteer est installé
    if command -v node >/dev/null 2>&1; then
        if [ -d "/home/myblog/backend/node_modules/puppeteer" ] || npm list puppeteer >/dev/null 2>&1; then
            log_info "Utilisation de Puppeteer pour capturer les erreurs..."
            local result=$(cd /home/myblog/backend && node "$js_script" "$url" 2>&1)
            
            if echo "$result" | grep -q "ERRORS_FOUND"; then
                log_error "Erreurs détectées sur $test_name"
                echo "$result" | grep -v "ERRORS_FOUND" | while read error_line; do
                    log_to_file "$CLIENT_ERRORS_LOG" "[$test_name] $error_line"
                    echo "   🔴 $error_line"
                done
                return 1
            else
                log_success "Aucune erreur détectée sur $test_name"
                return 0
            fi
        else
            log_warning "Puppeteer non installé, utilisation de curl..."
            test_with_curl "$url" "$test_name"
        fi
    else
        log_warning "Node.js non disponible, test basique..."
        test_with_curl "$url" "$test_name"
    fi
    
    rm -f "$js_script"
}

# Fonction de test avec curl (fallback)
test_with_curl() {
    local url=$1
    local test_name=$2
    
    local response=$(curl -s -w "%{http_code}" --max-time 15 "$url" 2>/dev/null)
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    log_info "Code réponse HTTP: $http_code"
    
    if [ "$http_code" != "200" ] && [ "$http_code" != "302" ]; then
        log_error "Erreur HTTP sur $test_name (Code: $http_code)"
        log_to_file "$CLIENT_ERRORS_LOG" "[$test_name] HTTP Error: $http_code"
        return 1
    fi
    
    # Rechercher des patterns d'erreur dans la réponse
    local error_patterns=(
        "useContext.*null"
        "Cannot read properties of null"
        "TypeError.*useContext"
        "Uncaught.*Error"
        "React.*Error"
    )
    
    local errors_found=false
    for pattern in "${error_patterns[@]}"; do
        if echo "$response_body" | grep -q "$pattern"; then
            log_warning "Pattern d'erreur détecté: $pattern"
            log_to_file "$CLIENT_ERRORS_LOG" "[$test_name] Pattern detected: $pattern"
            errors_found=true
        fi
    done
    
    if [ "$errors_found" = false ]; then
        log_success "Aucune erreur détectée dans la réponse HTML"
    fi
}

# Fonction pour analyser les logs existants
analyze_existing_logs() {
    echo ""
    log_info "🔍 Analyse des logs existants..."
    
    # Patterns d'erreurs React/useContext à rechercher
    local error_patterns=(
        "useContext.*null"
        "Cannot read properties of null.*useContext"
        "TypeError.*useContext"
        "useInRouterContext"
        "useMatch.*error"
        "Layout.*error"
        "renderWithHooks.*error"
        "React.*Error"
        "Uncaught TypeError"
        "chunk-.*error"
        "vite/deps.*error"
    )
    
    echo "📊 Recherche dans les logs backend..."
    local backend_errors=0
    for pattern in "${error_patterns[@]}"; do
        local count=$(grep -c "$pattern" "$LOG_DIR/backend.log" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            backend_errors=$((backend_errors + count))
            log_warning "Backend - '$pattern': $count occurrences"
        fi
    done
    
    echo "📊 Recherche dans les logs système..."
    local system_errors=0
    for pattern in "${error_patterns[@]}"; do
        local count=$(grep -c "$pattern" "$LOG_DIR/system.log" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            system_errors=$((system_errors + count))
            log_warning "Système - '$pattern': $count occurrences"
        fi
    done
    
    if [ "$backend_errors" -eq 0 ] && [ "$system_errors" -eq 0 ]; then
        log_info "Aucune erreur React/useContext trouvée dans les logs serveur"
        log_info "💡 Les erreurs useContext sont généralement côté client (navigateur)"
    else
        log_error "Total erreurs backend: $backend_errors"
        log_error "Total erreurs système: $system_errors"
    fi
}

# Fonction pour créer un rapport d'erreur
create_error_report() {
    local error_message="$1"
    local report_file="$LOG_DIR/useContext-error-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "🚨 RAPPORT D'ERREUR useContext"
        echo "============================="
        echo "Date: $(date)"
        echo "URL problématique: https://cms.bh-systems.be/admin/content-manager"
        echo ""
        echo "🔴 Erreur rapportée:"
        echo "$error_message"
        echo ""
        echo "🔍 ANALYSE:"
        echo "----------"
        echo "Type d'erreur: React useContext null reference"
        echo "Composant affecté: Layout (Router Context)"
        echo "Cause probable: Problème d'état React ou context React Router"
        echo ""
        echo "🛠️ SOLUTIONS RECOMMANDÉES:"
        echo "-------------------------"
        echo "1. Redémarrer Strapi: ./monitor-strapi.sh restart"
        echo "2. Vider le cache navigateur (Ctrl+Shift+R)"
        echo "3. Vérifier la configuration Vite"
        echo "4. Si persistant: Reconstruire les node_modules"
        echo ""
        echo "📊 ÉTAT DU SYSTÈME:"
        echo "------------------"
        ps aux | grep -E "(strapi|node)" | grep -v grep
        echo ""
        echo "📊 UTILISATION MÉMOIRE:"
        echo "----------------------"
        free -h
        echo ""
        echo "📊 LOGS RÉCENTS:"
        echo "---------------"
        tail -20 "$LOG_DIR/backend.log"
        
    } > "$report_file"
    
    log_success "Rapport créé: $report_file"
    echo "   📄 Consultez le rapport: cat $report_file"
}

# Fonction pour installer puppeteer si nécessaire
install_puppeteer() {
    log_info "🔧 Installation de Puppeteer pour capture d'erreurs avancée..."
    
    cd /home/myblog/backend
    if npm install puppeteer 2>/dev/null; then
        log_success "Puppeteer installé avec succès"
        return 0
    else
        log_warning "Échec installation Puppeteer, utilisation de curl"
        return 1
    fi
}

# Menu principal
show_menu() {
    echo ""
    echo "🔍 Capture d'erreurs côté client - Menu"
    echo "======================================="
    echo ""
    echo "1️⃣  📱 Tester admin local (localhost:1440)"
    echo "2️⃣  🌐 Tester admin production (cms.bh-systems.be)"
    echo "3️⃣  🔍 Analyser logs existants"
    echo "4️⃣  📊 Créer rapport d'erreur useContext"
    echo "5️⃣  🔧 Installer Puppeteer (capture avancée)"
    echo "6️⃣  📋 Afficher erreurs capturées"
    echo "7️⃣  Quitter"
    echo ""
    read -p "Choisissez une option (1-7): " choice
    
    case $choice in
        1) capture_client_errors "$LOCAL_ADMIN_URL" "Admin-Local" ;;
        2) capture_client_errors "$STRAPI_ADMIN_URL" "Admin-Production" ;;
        3) analyze_existing_logs ;;
        4) 
            echo ""
            echo "Entrez le message d'erreur complet:"
            read -r error_msg
            create_error_report "$error_msg"
            ;;
        5) install_puppeteer ;;
        6) 
            if [ -f "$CLIENT_ERRORS_LOG" ]; then
                echo ""
                log_info "📋 Dernières erreurs capturées:"
                tail -20 "$CLIENT_ERRORS_LOG"
            else
                log_info "Aucune erreur capturée pour le moment"
            fi
            ;;
        7) exit 0 ;;
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
    "test-local") capture_client_errors "$LOCAL_ADMIN_URL" "Admin-Local" ;;
    "test-prod") capture_client_errors "$STRAPI_ADMIN_URL" "Admin-Production" ;;
    "analyze") analyze_existing_logs ;;
    "report") 
        if [ -n "$2" ]; then
            create_error_report "$2"
        else
            echo "Usage: $0 report \"message d'erreur\""
        fi
        ;;
    *)
        echo "Usage: $0 {menu|test-local|test-prod|analyze|report}"
        echo ""
        echo "Options:"
        echo "  menu       - Menu interactif (défaut)"
        echo "  test-local - Tester admin local"
        echo "  test-prod  - Tester admin production"
        echo "  analyze    - Analyser logs existants"
        echo "  report     - Créer rapport d'erreur"
        exit 1
        ;;
esac
