-- =====================================================================
-- Schéma de la base de données — Marketplace de pièces PC d'occasion (V1)
-- Compatible MySQL 8 / MariaDB 10.5+
--
-- Utilisation :
--   mysql -u <utilisateur> -p marketplace_pc < sql/schema.sql
--
-- ATTENTION : ce script SUPPRIME les tables existantes avant de les recréer.
-- À utiliser uniquement en développement (toutes les données sont perdues).
-- =====================================================================

-- On supprime dans l'ordre inverse des dépendances :
-- une table référencée par une clé étrangère ne peut pas être supprimée avant
-- la table qui la référence.
DROP TABLE IF EXISTS user_components;
DROP TABLE IF EXISTS listing_photos;
DROP TABLE IF EXISTS listings;
DROP TABLE IF EXISTS components;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;


-- ---------------------------------------------------------------------
-- Utilisateurs
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    -- 255 caractères : password_hash() peut produire des hash plus longs à l'avenir
    password_hash VARCHAR(255) NOT NULL,
    -- Seul un admin peut importer le catalogue (CSV)
    role ENUM('user', 'admin') NOT NULL DEFAULT 'user',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    -- Deux comptes ne peuvent pas avoir le même email ni le même pseudo
    UNIQUE KEY uq_users_email (email),
    UNIQUE KEY uq_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ---------------------------------------------------------------------
-- Catégories de composants
-- Une table plutôt qu'un ENUM : ajouter une catégorie (V2) = un simple INSERT.
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Identifiant court et stable, utilisé dans le code PHP (ex. : 'cpu')
    slug VARCHAR(30) NOT NULL,
    -- Nom affiché à l'utilisateur
    name VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_categories_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO categories (slug, name) VALUES
    ('cpu', 'Processeur'),
    ('motherboard', 'Carte mère'),
    ('ram', 'Mémoire RAM'),
    ('gpu', 'Carte graphique'),
    ('psu', 'Alimentation');


-- ---------------------------------------------------------------------
-- Catalogue de composants (rempli par l'admin via import CSV)
-- Une seule table pour toutes les catégories : les colonnes techniques
-- qui ne concernent pas la catégorie restent à NULL.
-- ---------------------------------------------------------------------
CREATE TABLE components (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id INT UNSIGNED NOT NULL,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(150) NOT NULL,
    -- Processeur et carte mère (ex. : 'AM5', 'LGA1700')
    socket VARCHAR(30) NULL,
    -- Carte mère et RAM
    ram_type ENUM('DDR4', 'DDR5') NULL,
    -- Consommation en watts : processeur et carte graphique
    power_draw_w SMALLINT UNSIGNED NULL,
    -- Puissance fournie en watts : alimentation uniquement
    psu_capacity_w SMALLINT UNSIGNED NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    -- Empêche les doublons quand on ré-importe le même fichier CSV
    UNIQUE KEY uq_components_category_brand_model (category_id, brand, model),
    -- RESTRICT : impossible de supprimer une catégorie qui contient des composants
    CONSTRAINT fk_components_category
        FOREIGN KEY (category_id) REFERENCES categories (id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ---------------------------------------------------------------------
-- Annonces
-- ---------------------------------------------------------------------
CREATE TABLE listings (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Le vendeur : sert aussi à vérifier les droits (modifier/supprimer)
    user_id INT UNSIGNED NOT NULL,
    -- La pièce vendue, choisie dans le catalogue
    component_id INT UNSIGNED NOT NULL,
    -- DECIMAL et pas FLOAT : un prix doit être exact (pas d'erreur d'arrondi)
    price DECIMAL(8, 2) NOT NULL,
    -- "item_condition" et pas "condition" : CONDITION est un mot réservé MySQL
    item_condition ENUM('new', 'like_new', 'good', 'fair', 'for_parts') NOT NULL,
    city VARCHAR(100) NOT NULL,
    description TEXT NULL,
    status ENUM('active', 'sold') NOT NULL DEFAULT 'active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    -- Index pour accélérer les filtres de recherche
    KEY idx_listings_city (city),
    KEY idx_listings_price (price),
    -- Si un utilisateur supprime son compte, ses annonces disparaissent aussi
    CONSTRAINT fk_listings_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE,
    -- On ne peut pas supprimer du catalogue une pièce encore utilisée par une annonce
    CONSTRAINT fk_listings_component
        FOREIGN KEY (component_id) REFERENCES components (id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ---------------------------------------------------------------------
-- Photos des annonces
-- On stocke seulement le NOM du fichier ; l'image est sur le disque.
-- ---------------------------------------------------------------------
CREATE TABLE listing_photos (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    listing_id INT UNSIGNED NOT NULL,
    -- Nom aléatoire généré par PHP à l'upload (jamais le nom d'origine)
    filename VARCHAR(100) NOT NULL,
    -- Ordre d'affichage : la photo en position 0 est la photo principale
    position TINYINT UNSIGNED NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_listing_photos_filename (filename),
    -- Une photo n'a pas de sens sans son annonce
    CONSTRAINT fk_listing_photos_listing
        FOREIGN KEY (listing_id) REFERENCES listings (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ---------------------------------------------------------------------
-- "Ma config" : les pièces que possède chaque utilisateur
-- Table de liaison plusieurs-à-plusieurs entre users et components.
-- ---------------------------------------------------------------------
CREATE TABLE user_components (
    user_id INT UNSIGNED NOT NULL,
    component_id INT UNSIGNED NOT NULL,
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Clé primaire sur les deux colonnes : la même pièce ne peut pas
    -- être ajoutée deux fois à la config du même utilisateur
    PRIMARY KEY (user_id, component_id),
    CONSTRAINT fk_user_components_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_user_components_component
        FOREIGN KEY (component_id) REFERENCES components (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
