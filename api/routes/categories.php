<?php
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($id) {
        $stmt = $pdo->prepare('SELECT * FROM categories WHERE id = ?');
        $stmt->execute([$id]);
        $category = $stmt->fetch();
        if (!$category) error(404, 'Category not found');
        success('Category retrieved', $category);
    } else {
        $stmt = $pdo->query('SELECT * FROM categories ORDER BY id');
        $categories = $stmt->fetchAll();
        success('Categories retrieved', $categories);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getInput();
    validateRequired($data, ['name']);
    $stmt = $pdo->prepare('INSERT INTO categories (name, emoji, color, status, image_url) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([
        $data['name'],
        $data['emoji'] ?? '🏪',
        $data['color'] ?? '#1b3a5c',
        $data['status'] ?? 1,
        $data['image_url'] ?? null
    ]);
    $id = $pdo->lastInsertId();
    success('Category created', ['id' => $id]);
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    if (!$id) error(400, 'Category ID required');
    $data = getInput();
    $stmt = $pdo->prepare('UPDATE categories SET name = ?, emoji = ?, color = ?, status = ?, image_url = ? WHERE id = ?');
    $stmt->execute([
        $data['name'] ?? null,
        $data['emoji'] ?? null,
        $data['color'] ?? null,
        $data['status'] ?? null,
        $data['image_url'] ?? null,
        $id
    ]);
    success('Category updated');
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    if (!$id) error(400, 'Category ID required');
    $stmt = $pdo->prepare('DELETE FROM categories WHERE id = ?');
    $stmt->execute([$id]);
    success('Category deleted');
}

error(405, 'Method not allowed');
?>