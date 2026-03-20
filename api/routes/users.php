<?php
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($id) {
        $stmt = $pdo->prepare('SELECT id, username, prenom, nom, email, tel, role, status, last_login, created_at FROM users WHERE id = ?');
        $stmt->execute([$id]);
        $user = $stmt->fetch();
        if (!$user) error(404, 'User not found');
        success('User retrieved', $user);
    } else {
        $stmt = $pdo->query('SELECT id, username, prenom, nom, email, tel, role, status, last_login, created_at FROM users ORDER BY id');
        $users = $stmt->fetchAll();
        success('Users retrieved', $users);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getInput();
    validateRequired($data, ['username', 'password', 'prenom', 'nom']);
    $stmt = $pdo->prepare('INSERT INTO users (username, password, prenom, nom, email, tel, role, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
    $stmt->execute([
        $data['username'],
        password_hash($data['password'], PASSWORD_BCRYPT),
        $data['prenom'],
        $data['nom'],
        $data['email'] ?? null,
        $data['tel'] ?? null,
        $data['role'] ?? 'Vendeur',
        $data['status'] ?? 1
    ]);
    $id = $pdo->lastInsertId();
    success('User created', ['id' => $id]);
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    if (!$id) error(400, 'User ID required');
    $data = getInput();
    $updates = [];
    $params = [];
    if (isset($data['prenom'])) { $updates[] = 'prenom = ?'; $params[] = $data['prenom']; }
    if (isset($data['nom'])) { $updates[] = 'nom = ?'; $params[] = $data['nom']; }
    if (isset($data['email'])) { $updates[] = 'email = ?'; $params[] = $data['email']; }
    if (isset($data['tel'])) { $updates[] = 'tel = ?'; $params[] = $data['tel']; }
    if (isset($data['role'])) { $updates[] = 'role = ?'; $params[] = $data['role']; }
    if (isset($data['status'])) { $updates[] = 'status = ?'; $params[] = $data['status']; }
    if (isset($data['password'])) { $updates[] = 'password = ?'; $params[] = password_hash($data['password'], PASSWORD_BCRYPT); }
    if (empty($updates)) error(400, 'No fields to update');
    $params[] = $id;
    $stmt = $pdo->prepare('UPDATE users SET ' . implode(', ', $updates) . ' WHERE id = ?');
    $stmt->execute($params);
    success('User updated');
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    if (!$id) error(400, 'User ID required');
    $stmt = $pdo->prepare('DELETE FROM users WHERE id = ?');
    $stmt->execute([$id]);
    success('User deleted');
}

error(405, 'Method not allowed');
?>