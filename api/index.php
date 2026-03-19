<?php
require_once 'config.php';

// Parse URL
$request = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$request = str_replace('/pos/api', '', $request);
$parts = array_filter(explode('/', $request));
$endpoint = array_shift($parts) ?? 'status';
$id = array_shift($parts);

// Route Requests
switch ($endpoint) {
    case 'status':
        success('API is running', ['version' => API_VERSION]);
        break;
    case 'settings':
        require 'routes/settings.php';
        break;
    case 'categories':
        require 'routes/categories.php';
        break;
    case 'products':
        require 'routes/products.php';
        break;
    case 'users':
        require 'routes/users.php';
        break;
    case 'auth':
        require 'routes/auth.php';
        break;
    case 'sales':
        require 'routes/sales.php';
        break;
    case 'logs':
        require 'routes/logs.php';
        break;
    default:
        error(404, 'Endpoint not found');
}
?>