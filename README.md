# Kompat

Site d'annonces de pièces PC d'occasion avec vérification de compatibilité.
Quand on achète une pièce d'occasion, on ne sait pas toujours si elle fonctionnera avec son PC :
Kompat compare la pièce de l'annonce avec la configuration déclarée par l'utilisateur.

> Projet en cours de développement.

## Fonctionnalités

### Fait
- Schéma de base de données de la V1 (utilisateurs, catégories, composants, annonces, photos, configuration utilisateur)
- Connexion PHP ↔ MySQL avec PDO, identifiants hors du dépôt
- Page de test listant les catégories de composants

### Prévu — V1
- Inscription / connexion / déconnexion
- Catalogue de composants (5 catégories : processeur, carte mère, RAM, carte graphique, alimentation), rempli par import CSV (admin)
- Annonces liées à un composant du catalogue (prix, état, ville, photos)
- Recherche et filtres (catégorie, prix, ville)
- Page « Ma config » : déclarer les pièces que l'on possède
- Vérification de compatibilité et badge « compatible avec ta config » :
  - socket processeur = socket carte mère
  - type de RAM (DDR4/DDR5) supporté par la carte mère
  - puissance de l'alimentation suffisante (avec marge)

### Prévu — V2
- Messagerie acheteur / vendeur
- Favoris
- Signalement et modération
- Nouvelles catégories et règles de compatibilité

## Stack technique
- **PHP natif** (sans framework) : maîtriser les bases (requêtes HTTP, sessions, sécurité) avant d'utiliser un framework.
- **MySQL / MariaDB via PDO** : requêtes préparées, gestion des erreurs par exceptions.
- **HTML, CSS, JavaScript vanilla** : aucune dépendance externe.

## Installation en local

### Prérequis
- PHP 8 avec l'extension `pdo_mysql`
- MySQL 8 ou MariaDB 10.5+

### Étapes
1. Créer la base et importer le schéma :
   ```bash
   mysql -u <utilisateur> -p -e "CREATE DATABASE marketplace_pc CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
   mysql -u <utilisateur> -p marketplace_pc < sql/schema.sql
   ```
   ⚠️ `sql/schema.sql` supprime les tables existantes avant de les recréer.
2. Créer le fichier de configuration à partir de l'exemple, puis y mettre ses identifiants :
   ```bash
   cp config/config.example.php config/config.php
   ```
3. Lancer le serveur de développement avec `public/` comme racine :
   ```bash
   php -S localhost:8000 -t public
   ```
4. Ouvrir http://localhost:8000 : la liste des catégories s'affiche.

## Structure des dossiers
```
config/      configuration (config.php ignoré par Git, config.example.php versionné)
includes/    code PHP partagé (connexion à la base)
public/      seul dossier exposé au navigateur (pages du site)
sql/         schéma de la base de données
```

## Sécurité en place
- Identifiants de base de données hors du dépôt (`config/config.php` dans `.gitignore`)
- Seul le dossier `public/` est servi par le serveur web
- PDO en mode exception, vraies requêtes préparées (`EMULATE_PREPARES = false`), encodage `utf8mb4`
- En cas d'échec de connexion : message générique pour l'utilisateur, détail uniquement dans le journal du serveur
- Échappement des données affichées avec `htmlspecialchars`
