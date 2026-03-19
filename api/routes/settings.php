<?php
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->query('SELECT `key`, `value` FROM settings');
    $settings = [];
    while ($row = $stmt->fetch()) {
        $settings[$row['key']] = $row['value'];
    }
    success('Settings retrieved', $settings);
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data = getInput();
    validateRequired($data, ['key', 'value']);
    $stmt = $pdo->prepare('INSERT INTO settings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = ?');
    $stmt->execute([$data['key'], $data['value'], $data['value']]);
    success('Setting updated', ['key' => $data['key'], 'value' => $data['value']]);
}

error(405, 'Method not allowed');
?>