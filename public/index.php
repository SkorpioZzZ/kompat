<?php
// Page de test : vérifie que la connexion à la base fonctionne
// en affichant la liste des catégories.

require __DIR__ . '/../includes/db.php';

$pdo = getDatabaseConnection();

// Requête fixe, sans aucune donnée venant de l'utilisateur :
// pas besoin de requête préparée ici, query() suffit.
$statement = $pdo->query('SELECT id, name FROM categories ORDER BY name');
$categories = $statement->fetchAll();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Kompat — test de connexion</title>
</head>
<body>
    <h1>Catégories</h1>

    <ul>
        <?php foreach ($categories as $category): ?>
            <!-- htmlspecialchars : empêche d'injecter du HTML/JavaScript via un nom de catégorie -->
            <li><?php echo htmlspecialchars($category['name']); ?></li>
        <?php endforeach; ?>
    </ul>
</body>
</html>
