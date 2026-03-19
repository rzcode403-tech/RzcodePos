<?php
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($id) {
        $stmt = $pdo->prepare('SELECT * FROM products WHERE id = ?');
        $stmt->execute([$id]);
        $product = $stmt->fetch();
        if (!$product) error(404, 'Product not found');
        success('Product retrieved', $product);
    } else {
        $query = 'SELECT * FROM products WHERE 1=1';
        $params = [];
        if (!empty($_GET['category_id'])) {
            $query .= ' AND category_id = ?';
            $params[] = $_GET['category_id'];
        }
        if (!empty($_GET['status'])) {
            $query .= ' AND status = ?';
            $params[] = $_GET['status'];
        }
        if (!empty($_GET['search'])) {
            $query .= ' AND (name LIKE ? OR barcode LIKE ?)';
            $search = '%' . $_GET['search'] . '%';
            $params[] = $search;
            $params[] = $search;
        }
        $query .= ' ORDER BY id';
        $stmt = $pdo->prepare($query);
        $stmt->execute($params);
        $products = $stmt->fetchAll();
        success('Products retrieved', $products);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getInput();
    validateRequired($data, ['name', 'category_id', 'price']);
    $stmt = $pdo->prepare('INSERT INTO products (name, category_id, price, tva, stock, emoji, image_url, barcode, description, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    $stmt->execute([
        $data['name'],
        $data['category_id'],
        $data['price'],
        $data['tva'] ?? 0,
        $data['stock'] ?? 0,
        $data['emoji'] ?? '📦',
        $data['image_url'] ?? null,
        $data['barcode'] ?? null,
        $data['description'] ?? null,
        $data['status'] ?? 1
    ]);
    $id = $pdo->lastInsertId();
    success('Product created', ['id' => $id]);
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    if (!$id) error(400, 'Product ID required');
    $data = getInput();
    $stmt = $pdo->prepare('UPDATE products SET name = ?, category_id = ?, price = ?, tva = ?, stock = ?, emoji = ?, image_url = ?, barcode = ?, description = ?, status = ? WHERE id = ?');
    $stmt->execute([
        $data['name'] ?? null,
        $data['category_id'] ?? null,
        $data['price'] ?? null,
        $data['tva'] ?? null,
        $data['stock'] ?? null,
        $data['emoji'] ?? null,
        $data['image_url'] ?? null,
        $data['barcode'] ?? null,
        $data['description'] ?? null,
        $data['status'] ?? null,
        $id
    ]);
    success('Product updated');
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    if (!$id) error(400, 'Product ID required');
    $stmt = $pdo->prepare('DELETE FROM products WHERE id = ?');
    $stmt->execute([$id]);
    success('Product deleted');
}

error(405, 'Method not allowed');
?>