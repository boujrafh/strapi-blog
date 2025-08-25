#!/bin/bash

# Script pour créer et publier des versions (tags) Git
# Suit la convention Semantic Versioning (SemVer): MAJOR.MINOR.PATCH

echo "🏷️  Script de gestion des versions Git"
echo "====================================="

# Fonction pour afficher l'aide
show_help() {
    echo ""
    echo "📖 Guide des versions Semantic Versioning:"
    echo ""
    echo "Format: MAJOR.MINOR.PATCH (ex: 1.2.3)"
    echo ""
    echo "🔴 MAJOR (1.x.x) - Changements incompatibles:"
    echo "   • Modifications de l'API breaking"
    echo "   • Changements d'architecture majeurs" 
    echo "   • Suppressions de fonctionnalités"
    echo ""
    echo "🟡 MINOR (x.1.x) - Nouvelles fonctionnalités:"
    echo "   • Ajout de nouvelles features"
    echo "   • Améliorations compatibles"
    echo "   • Nouvelles APIs rétro-compatibles"
    echo ""
    echo "🟢 PATCH (x.x.1) - Corrections:"
    echo "   • Bug fixes"
    echo "   • Corrections de sécurité"
    echo "   • Optimisations mineures"
    echo ""
    echo "🎯 Exemples d'usage:"
    echo "   ./release.sh patch    # 1.1.0 → 1.1.1"
    echo "   ./release.sh minor    # 1.1.1 → 1.2.0" 
    echo "   ./release.sh major    # 1.2.0 → 2.0.0"
    echo "   ./release.sh 1.5.2    # Version spécifique"
    echo ""
}

# Fonction pour obtenir le dernier tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
}

# Fonction pour incrémenter une version
increment_version() {
    local version=$1
    local type=$2
    
    # Supprimer le 'v' si présent
    version=${version#v}
    
    IFS='.' read -r major minor patch <<< "$version"
    
    case $type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo "❌ Type de version invalide: $type"
            return 1
            ;;
    esac
    
    echo "v${major}.${minor}.${patch}"
}

# Fonction pour valider une version
validate_version() {
    local version=$1
    # Regex pour valider le format semver
    if [[ $version =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Vérifier que nous sommes dans un repository Git
if [ ! -d ".git" ]; then
    echo "❌ Erreur: Pas un repository Git!"
    exit 1
fi

# Vérifier qu'il n'y a pas de modifications non commitées
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Modifications non commitées détectées!"
    echo ""
    git status --short
    echo ""
    read -p "🤔 Voulez-vous commiter automatiquement ? (y/N): " auto_commit
    if [[ $auto_commit =~ ^[Yy]$ ]]; then
        echo "📝 Création d'un commit automatique..."
        git add .
        git commit -m "🔧 chore: Prepare release

📦 Auto-commit before version tagging
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
        echo "✅ Commit créé"
    else
        echo "❌ Veuillez commiter vos modifications avant de créer une version."
        echo "💡 Utilisez: git add . && git commit -m 'votre message'"
        exit 1
    fi
fi

# Obtenir la version actuelle
current_tag=$(get_latest_tag)
echo "📋 Version actuelle: $current_tag"

# Gestion des arguments
if [ $# -eq 0 ]; then
    show_help
    echo "🎯 Version actuelle: $current_tag"
    echo ""
    read -p "💭 Quel type de version créer ? (major/minor/patch): " version_type
else
    version_type=$1
fi

# Déterminer la nouvelle version
case $version_type in
    "major"|"minor"|"patch")
        new_version=$(increment_version "$current_tag" "$version_type")
        if [ $? -ne 0 ]; then
            exit 1
        fi
        ;;
    "help"|"-h"|"--help")
        show_help
        exit 0
        ;;
    *)
        # Vérifier si c'est une version spécifique
        test_version=$version_type
        # Ajouter 'v' si pas présent
        if [[ ! $test_version =~ ^v ]]; then
            test_version="v$test_version"
        fi
        
        if validate_version "$test_version"; then
            new_version=$test_version
        else
            echo "❌ Format de version invalide: $version_type"
            echo "📖 Format attendu: MAJOR.MINOR.PATCH (ex: 1.2.3)"
            echo "💡 Ou utilisez: major, minor, patch"
            exit 1
        fi
        ;;
esac

echo ""
echo "🔄 Transition de version:"
echo "   📍 Actuelle: $current_tag"
echo "   🎯 Nouvelle: $new_version"
echo ""

# Demander confirmation
read -p "🤔 Confirmer la création de cette version ? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Opération annulée."
    exit 0
fi

# Demander le message de release
echo ""
echo "📝 Message de release (laissez vide pour un message automatique):"
read -p "💬 Décrivez les changements: " release_message

if [ -z "$release_message" ]; then
    # Message automatique basé sur le type
    case $version_type in
        "major")
            release_message="🚀 Major Release $new_version

🔴 Breaking Changes:
- Modifications importantes de l'architecture
- Vérifiez la documentation de migration

⚠️  Cette version contient des changements incompatibles"
            ;;
        "minor")
            release_message="✨ Feature Release $new_version

🟡 New Features:
- Nouvelles fonctionnalités ajoutées
- Améliorations de l'interface
- Extensions des capacités existantes

✅ Rétro-compatible avec la version précédente"
            ;;
        "patch")
            release_message="🛠️  Patch Release $new_version

🟢 Bug Fixes:
- Corrections de bugs
- Améliorations de stabilité
- Optimisations de performance

🔧 Mise à jour recommandée pour tous les utilisateurs"
            ;;
        *)
            release_message="📦 Release $new_version

🔄 Version spécifique
🕐 $(date '+%Y-%m-%d %H:%M:%S')"
            ;;
    esac
fi

echo ""
echo "🏷️  Création du tag..."

# Créer le tag annoté
if git tag -a "$new_version" -m "$release_message"; then
    echo "✅ Tag $new_version créé avec succès"
    
    # Pousser vers GitHub
    echo ""
    echo "📤 Push vers GitHub..."
    if git push origin main --tags; then
        echo ""
        echo "🎉 ✅ VERSION $new_version PUBLIÉE AVEC SUCCÈS!"
        echo ""
        echo "🌐 Liens utiles:"
        echo "   📦 Repository: https://github.com/boujrafh/strapi-blog"
        echo "   🏷️  Releases: https://github.com/boujrafh/strapi-blog/releases"
        echo "   📋 Tags: https://github.com/boujrafh/strapi-blog/tags"
        echo ""
        echo "📚 Prochaines étapes:"
        echo "   1. 📝 Créez une release note sur GitHub"
        echo "   2. 📢 Annoncez les changements à votre équipe"
        echo "   3. 🔄 Mettez à jour la documentation si nécessaire"
        echo ""
        echo "💡 Astuce: Visitez GitHub pour créer une release note détaillée!"
    else
        echo "❌ Erreur lors du push vers GitHub"
        echo "🔧 Le tag existe localement, vous pouvez retry avec:"
        echo "   git push origin main --tags"
        exit 1
    fi
else
    echo "❌ Erreur lors de la création du tag"
    exit 1
fi
