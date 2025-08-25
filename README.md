# 🚀 Strapi Blog Infrastructure

## 📋 Description

Infrastructure complète pour un blog moderne avec Strapi CMS et React Router frontend, déployé avec nginx et SSL.

## 🌐 URLs de Production

- **Frontend** : https://blog.votre-domaine.com
- **Backend CMS** : https://cms.votre-domaine.com/admin
- **API** : https://cms.votre-domaine.com/api

## 🏗️ Architecture

```
├── backend/          # Strapi CMS (API)
├── frontend/         # React Router (Interface)
├── reverse-proxy/    # Configuration nginx
├── deploy-nginx.sh   # Script de déploiement nginx
├── nginx-cms.conf    # Configuration nginx CMS
├── nginx-blog.conf   # Configuration nginx frontend
└── release.sh        # Script de gestion des versions
```

## �️ Technologies

- **Backend**: Strapi v5.x, Node.js, PostgreSQL
- **Frontend**: React Router, Vite, TypeScript
- **Reverse Proxy**: Nginx
- **SSL**: Let's Encrypt (certbot)
- **Hosting**: VPS avec domaines personnalisés

## ⚙️ Configuration

### Variables d'environnement

#### Backend (.env)
```bash
# Server
HOST=0.0.0.0
PORT=1440
SERVER_URL=https://cms.votre-domaine.com

# Secrets (⚠️ À générer avec openssl rand -base64 32)
APP_KEYS=your-app-keys
API_TOKEN_SALT=your-api-token-salt
ADMIN_JWT_SECRET=your-admin-jwt-secret
TRANSFER_TOKEN_SALT=your-transfer-token-salt
ENCRYPTION_KEY=your-encryption-key

# Database
DATABASE_URL=your-postgresql-database-url
DATABASE_CONNECTION_TIMEOUT=60000
JWT_SECRET=your-jwt-secret

# Media (Cloudinary)
CLOUDINARY_NAME=your-cloudinary-name
CLOUDINARY_KEY=your-cloudinary-key
CLOUDINARY_SECRET=your-cloudinary-secret
```

#### Frontend (.env)
```bash
VITE_API_URL="https://cms.votre-domaine.com/api"
VITE_STRAPI_URL="https://cms.votre-domaine.com"
VITE_API_BASE_URL="https://cms.votre-domaine.com"
VITE_STRAPI_TOKEN="your-strapi-api-token"
```

## 🚀 Déploiement

### 1. Backend Strapi (Port 1440)
```bash
cd backend/
npm install
npm run build
npm run develop  # Développement
# ou
npm start        # Production
```

**Important** : Strapi v5 nécessite la configuration `allowedHosts` dans `src/admin/vite.config.ts` :
```typescript
server: {
  allowedHosts: [
    'cms.votre-domaine.com',
    'localhost',
    '127.0.0.1',
  ],
}
```

### 2. Frontend React Router (Port 5173)
```bash
cd frontend/
npm install
npm run dev      # Développement
# ou
npm run build && npm run start  # Production
```

### 3. Configuration Nginx
```bash
# Déployer les configurations nginx
./deploy-nginx.sh

# Générer les certificats SSL
sudo certbot --nginx -d blog.votre-domaine.com
sudo certbot --nginx -d cms.votre-domaine.com
```

## ⚙️ Variables d'Environnement

### Backend (.env)
```bash
# Server
HOST=0.0.0.0
PORT=1440
SERVER_URL=https://cms.votre-domaine.com

# Database (PostgreSQL)
DATABASE_URL=postgresql://user:pass@host/db?sslmode=require

# Secrets (générés automatiquement)
APP_KEYS=...
ADMIN_JWT_SECRET=...
API_TOKEN_SALT=...
```

### Frontend (.env)
```bash
# Development
VITE_API_URL="http://localhost:1440/api"
VITE_STRAPI_URL="http://localhost:1440"
```

### Frontend (.env.production)
```bash
# Production
VITE_API_URL="https://cms.votre-domaine.com/api"
VITE_STRAPI_URL="https://cms.votre-domaine.com"
VITE_STRAPI_TOKEN="your-api-token"
```

## 📊 Content Types Configurés

### Posts
- `title` : Titre de l'article
- `slug` : URL friendly
- `excerpt` : Résumé
- `body` : Contenu complet (Markdown)
- `image` : Image de couverture
- `date` : Date de publication

### Projects
- `title` : Nom du projet
- `description` : Description courte
- `url` : Lien vers le projet
- `date` : Date de création
- `category` : Catégorie (Fullstack, Frontend, etc.)
- `featured` : Projet mis en avant
- `image` : Image du projet

## 🔐 Authentification API

L'API utilise des tokens Bearer pour l'authentification :
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://cms.votre-domaine.com/api/posts
```

## 🛠️ Dépannage

### 1. Erreur "Upgrade Required" (426)
- Vérifier que Strapi est démarré sur le port 1440
- Vérifier la configuration `allowedHosts` dans Vite

### 2. Erreur 502 Bad Gateway
- Strapi n'est pas démarré ou inaccessible
- Vérifier les logs nginx : `sudo tail -f /var/log/nginx/error.log`

### 3. Erreur JSON Parse
- L'API retourne du HTML au lieu de JSON
- Vérifier que les tokens API sont corrects
- Vérifier les permissions Strapi

### 4. Problèmes SSL
```bash
# Renouveler les certificats
sudo certbot renew

# Tester la configuration nginx
sudo nginx -t
```

## 📦 Commandes Utiles

```bash
# Redémarrer tous les services
pkill -f "npm\|strapi"
cd backend && npm run develop &
cd frontend && npm run dev &

# Vérifier les ports
lsof -i :1440  # Strapi
lsof -i :5173  # Frontend

# Logs nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Statut des services
sudo systemctl status nginx
```

## 🔄 Mise à Jour

1. **Backend** : Redémarrer Strapi après modifications
2. **Frontend** : Redémarrer Vite après modifications
3. **Nginx** : `sudo systemctl reload nginx` après changement de config

## 📝 Notes de Production

- Strapi prend ~30 secondes à démarrer complètement
- Les certificats SSL se renouvellent automatiquement
- La base de données PostgreSQL peut être hébergée sur différents providers
- Les images peuvent être gérées via Cloudinary ou autre service

## 🎯 Prochaines Étapes

1. ✅ Configuration production fonctionnelle
2. 🔄 Mise en place du CI/CD
3. 📊 Monitoring et analytics
4. 🔒 Optimisations de sécurité
5. ⚡ Optimisations de performance
