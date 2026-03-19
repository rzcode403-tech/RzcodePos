<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = getInput();
    validateRequired($data, ['username', 'password']);
    $stmt = $pdo->prepare('SELECT * FROM users WHERE username = ? AND status = 1');
    $stmt->execute([$data['username']]);
    $user = $stmt->fetch();
    if (!$user || !password_verify($data['password'], $user['password'])) {
        error(401, 'Invalid credentials');
    }
    $stmt = $pdo->prepare('UPDATE users SET last_login = NOW() WHERE id = ?');
    $stmt->execute([$user['id']]);
    unset($user['password']);
    success('Login successful', $user);
}

error(405, 'Method not allowed');
?>