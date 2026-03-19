<?php
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $query = 'SELECT * FROM logs WHERE 1=1';
    $params = [];
    if (!empty($_GET['user_id'])) {
        $query .= ' AND user_id = ?';
        $params[] = $_GET['user_id'];
    }
    if (!empty($_GET['action'])) {
        $query .= ' AND action LIKE ?';
        $params[] = $_GET['action'] . '%';
    }
    if (!empty($_GET['date_from'])) {
        $query .= ' AND log_date >= ?';
        $params[] = $_GET['date_from'];
    }
    $query .= ' ORDER BY log_date DESC LIMIT 500';
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $logs = $stmt->fetchAll();
    success('Logs retrieved', $logs);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getInput();
    validateRequired($data, ['id', 'action', 'log_date']);
    $stmt = $pdo->prepare('INSERT INTO logs (id, user_id, username, prenom, role, action, details, log_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
    $stmt->execute([
        $data['id'],
        $data['user_id'] ?? null,
        $data['username'] ?? null,
        $data['prenom'] ?? null,
        $data['role'] ?? null,
        $data['action'],
        $data['details'] ?? null,
        $data['log_date']
    ]);
    success('Log created');
}

error(405, 'Method not allowed');
?>