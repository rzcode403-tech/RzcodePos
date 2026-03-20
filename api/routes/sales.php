<?php
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($id) {
        $stmt = $pdo->prepare('SELECT * FROM sales WHERE id = ?');
        $stmt->execute([$id]);
        $sale = $stmt->fetch();
        if (!$sale) error(404, 'Sale not found');
        $stmt = $pdo->prepare('SELECT * FROM sale_items WHERE sale_id = ?');
        $stmt->execute([$id]);
        $sale['items'] = $stmt->fetchAll();
        success('Sale retrieved', $sale);
    } else {
        $query = 'SELECT * FROM sales WHERE 1=1';
        $params = [];
        if (!empty($_GET['user_id'])) {
            $query .= ' AND user_id = ?';
            $params[] = $_GET['user_id'];
        }
        if (!empty($_GET['date_from'])) {
            $query .= ' AND sale_date >= ?';
            $params[] = $_GET['date_from'];
        }
        if (!empty($_GET['date_to'])) {
            $query .= ' AND sale_date <= ?';
            $params[] = $_GET['date_to'];
        }
        $query .= ' ORDER BY sale_date DESC LIMIT 500';
        $stmt = $pdo->prepare($query);
        $stmt->execute($params);
        $sales = $stmt->fetchAll();
        success('Sales retrieved', $sales);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getInput();
    validateRequired($data, ['id', 'user_id', 'cashier', 'sale_date', 'items', 'total']);
    $stmt = $pdo->prepare('INSERT INTO sales (id, user_id, cashier, sale_date, subtotal, tax, total, payment_method, amount_given, change_amount, items_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    $stmt->execute([
        $data['id'],
        $data['user_id'],
        $data['cashier'],
        $data['sale_date'],
        $data['subtotal'] ?? 0,
        $data['tax'] ?? 0,
        $data['total'],
        $data['payment_method'] ?? 'Espèces',
        $data['amount_given'] ?? 0,
        $data['change_amount'] ?? 0,
        count($data['items'] ?? [])
    ]);
    $itemStmt = $pdo->prepare('INSERT INTO sale_items (sale_id, product_id, product_name, emoji, price, tva, quantity, line_total) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
    foreach ($data['items'] as $item) {
        $itemStmt->execute([
            $data['id'],
            $item['id'] ?? null,
            $item['name'],
            $item['emoji'] ?? null,
            $item['price'],
            $item['tva'] ?? 0,
            $item['qty'],
            $item['total'] ?? ($item['price'] * (1 + ($item['tva'] ?? 0) / 100) * $item['qty'])
        ]);
    }
    success('Sale created', ['id' => $data['id']]);
}

error(405, 'Method not allowed');
?>