<?php
// API Configuration
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database Configuration
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'rzcode_pos');

// API Configuration
define('API_VERSION', '1.0.0');
define('API_URL', 'https://rzcode.tn/pos/api');

// Response Helper
function response($status, $message, $data = null) {
    http_response_code($status);
    echo json_encode([
        'status' => $status,
        'message' => $message,
        'data' => $data,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    exit();
}

// Error Handler
function error($code, $message) {
    response($code, $message, null);
}

// Success Handler
function success($message, $data = null) {
    response(200, $message, $data);
}

// Database Connection
try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
} catch (PDOException $e) {
    error(500, 'Database connection failed: ' . $e->getMessage());
}

// Get Request Data
function getInput() {
    $input = file_get_contents('php://input');
    return json_decode($input, true) ?? $_GET;
}

// Validate Required Fields
function validateRequired($data, $fields) {
    foreach ($fields as $field) {
        if (empty($data[$field])) {
            error(400, "Field '$field' is required");
        }
    }
}
?>