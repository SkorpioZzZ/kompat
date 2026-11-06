<?php
// Connexion à la base de données MySQL/MariaDB avec PDO.
// Ce fichier est inclus par les pages qui ont besoin de la base.

function getDatabaseConnection()
{
    // On lit les identifiants dans le fichier de config (ignoré par Git).
    // __DIR__ = dossier de ce fichier : le chemin marche quelle que soit la page qui l'inclut.
    $config = require __DIR__ . '/../config/config.php';

    // Le DSN dit à PDO quel type de base utiliser et où la trouver.
    // charset=utf8mb4 : pour que les accents (et emoji) soient échangés correctement.
    $dsn = 'mysql:host=' . $config['host']
        . ';port=' . $config['port']
        . ';dbname=' . $config['dbname']
        . ';charset=utf8mb4';

    $options = [
        // En cas d'erreur SQL, PDO lance une exception au lieu de rester silencieux.
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        // Les lignes reviennent sous forme de tableau associatif : $row['name'].
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        // Vraies requêtes préparées côté MySQL (pas simulées par PHP).
        PDO::ATTR_EMULATE_PREPARES => false,
    ];

    try {
        $pdo = new PDO($dsn, $config['user'], $config['password'], $options);
    } catch (PDOException $exception) {
        // Le détail de l'erreur va dans le journal du serveur, pas à l'écran :
        // il pourrait révéler le nom d'utilisateur, l'hôte ou la structure de la base.
        error_log('Erreur de connexion BDD : ' . $exception->getMessage());

        // L'utilisateur ne voit qu'un message générique.
        http_response_code(500);
        echo 'Le site est momentanément indisponible. Merci de réessayer plus tard.';
        exit;
    }

    return $pdo;
}
